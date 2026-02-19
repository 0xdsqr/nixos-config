package scaffold

import (
	"bytes"
	"cmp"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"text/template"
)

type Runtime string

const (
	RuntimeGo Runtime = "go"
)

type runtimeProfile struct {
	ShellMessage     string
	DevPackages      []string
	TreefmtPrograms  []string
	GitignoreEntries []string
}

type templateData struct {
	ShellMessage     string
	DevPackages      []string
	TreefmtPrograms  []string
	GitignoreEntries []string
	ProjectName      string
	ModulePath       string
	Greeting         string
	BinaryName       string
}

func ParseRuntime(value string) (Runtime, error) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "go", "golang":
		return RuntimeGo, nil
	default:
		return "", fmt.Errorf("unknown runtime: %s (supported for now: go|golang)", value)
	}
}

func BootstrapRepo(targetPath string, runtimeKind Runtime) ([]string, error) {
	if strings.TrimSpace(targetPath) == "" {
		return nil, errors.New("target path cannot be empty")
	}

	data, err := buildTemplateData(targetPath, runtimeKind)
	if err != nil {
		return nil, err
	}

	files, err := templatesForRuntime(runtimeKind, data)
	if err != nil {
		return nil, err
	}

	cleanTarget := filepath.Clean(targetPath)
	if err := os.MkdirAll(cleanTarget, 0o755); err != nil {
		return nil, fmt.Errorf("failed to create target directory: %w", err)
	}

	paths := sortedKeys(files)
	for _, relPath := range paths {
		absPath := filepath.Join(cleanTarget, relPath)
		if _, err := os.Stat(absPath); err == nil {
			return nil, fmt.Errorf("refusing to overwrite existing file: %s", relPath)
		} else if !errors.Is(err, os.ErrNotExist) {
			return nil, fmt.Errorf("failed checking %s: %w", relPath, err)
		}
	}

	created := make([]string, 0, len(paths))
	createdAbs := make([]string, 0, len(paths))
	for _, relPath := range paths {
		absPath := filepath.Join(cleanTarget, relPath)
		if err := os.MkdirAll(filepath.Dir(absPath), 0o755); err != nil {
			rollbackFiles(createdAbs)
			return nil, fmt.Errorf("failed to create directory for %s: %w", relPath, err)
		}
		if err := writeFileAtomic(absPath, []byte(files[relPath]), 0o644); err != nil {
			rollbackFiles(createdAbs)
			return nil, fmt.Errorf("failed to write %s: %w", relPath, err)
		}
		created = append(created, relPath)
		createdAbs = append(createdAbs, absPath)
	}

	return created, nil
}

func buildTemplateData(targetPath string, runtimeKind Runtime) (templateData, error) {
	profile, err := profileForRuntime(runtimeKind)
	if err != nil {
		return templateData{}, err
	}

	projectName, err := inferProjectName(targetPath)
	if err != nil {
		return templateData{}, err
	}

	return templateData{
		ShellMessage:     profile.ShellMessage,
		DevPackages:      profile.DevPackages,
		TreefmtPrograms:  profile.TreefmtPrograms,
		GitignoreEntries: profile.GitignoreEntries,
		ProjectName:      projectName,
		ModulePath:       fmt.Sprintf("github.com/your-org/%s", projectName),
		Greeting:         fmt.Sprintf("hello from %s", projectName),
		BinaryName:       projectName,
	}, nil
}

func inferProjectName(targetPath string) (string, error) {
	clean := filepath.Clean(targetPath)
	base := filepath.Base(clean)

	if base == "." || base == string(filepath.Separator) || base == "" {
		cwd, err := os.Getwd()
		if err != nil {
			return "", fmt.Errorf("failed to infer project name from current directory: %w", err)
		}
		base = filepath.Base(cwd)
	}

	name := slugify(base)
	if name == "" {
		return "", fmt.Errorf("could not infer project name from path: %s", targetPath)
	}
	return name, nil
}

func slugify(value string) string {
	var b strings.Builder
	prevDash := false

	for _, r := range strings.ToLower(value) {
		isAlphaNum := (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9')
		if isAlphaNum {
			b.WriteRune(r)
			prevDash = false
			continue
		}
		if !prevDash {
			b.WriteByte('-')
			prevDash = true
		}
	}

	slug := strings.Trim(b.String(), "-")
	if slug == "" {
		return ""
	}
	if slug[0] >= '0' && slug[0] <= '9' {
		slug = "app-" + slug
	}
	return slug
}

func templatesForRuntime(runtimeKind Runtime, data templateData) (map[string]string, error) {
	files, err := renderBaseFiles(data)
	if err != nil {
		return nil, err
	}

	runtimeFiles, err := renderRuntimeFiles(runtimeKind, data)
	if err != nil {
		return nil, err
	}

	for k, v := range runtimeFiles {
		files[k] = v
	}
	return files, nil
}

func renderBaseFiles(data templateData) (map[string]string, error) {
	flake, err := renderTemplate("flake", flakeTemplate, data)
	if err != nil {
		return nil, err
	}
	devshell, err := renderTemplate("devshell", devshellTemplate, data)
	if err != nil {
		return nil, err
	}
	treefmt, err := renderTemplate("treefmt", treefmtTemplate, data)
	if err != nil {
		return nil, err
	}
	gitignore, err := renderTemplate("gitignore", gitignoreTemplate, data)
	if err != nil {
		return nil, err
	}

	return map[string]string{
		".envrc":           envrcTemplate,
		".gitignore":       gitignore,
		"flake.nix":        flake,
		"shell.nix":        shellTemplate,
		"nix/devshell.nix": devshell,
		"nix/treefmt.nix":  treefmt,
	}, nil
}

func renderRuntimeFiles(runtimeKind Runtime, data templateData) (map[string]string, error) {
	if runtimeKind != RuntimeGo {
		return nil, fmt.Errorf("unsupported runtime template: %s", runtimeKind)
	}

	goMod, err := renderTemplate("go.mod", goModTemplate, data)
	if err != nil {
		return nil, err
	}
	goMain, err := renderTemplate("go-main", goMainTemplate, data)
	if err != nil {
		return nil, err
	}
	goMainTest, err := renderTemplate("go-main-test", goMainTestTemplate, data)
	if err != nil {
		return nil, err
	}
	goPackage, err := renderTemplate("go-package", goPackageNixTemplate, data)
	if err != nil {
		return nil, err
	}
	return map[string]string{
		"go.mod": goMod,
		fmt.Sprintf("cmd/%s/main.go", data.ProjectName):      goMain,
		fmt.Sprintf("cmd/%s/main_test.go", data.ProjectName): goMainTest,
		"nix/package.nix": goPackage,
	}, nil
}

func profileForRuntime(runtimeKind Runtime) (runtimeProfile, error) {
	if runtimeKind != RuntimeGo {
		return runtimeProfile{}, fmt.Errorf("unsupported runtime template: %s", runtimeKind)
	}

	return runtimeProfile{
		ShellMessage: "Go + Nix toolchain ready",
		DevPackages: []string{
			"git",
			"just",
			"direnv",
			"go",
			"gopls",
			"gotools",
			"golangci-lint",
			"nil",
			"nixfmt",
		},
		TreefmtPrograms: []string{
			"programs.nixfmt.enable = true;",
			"programs.gofmt.enable = true;",
			"programs.goimports.enable = true;",
		},
		GitignoreEntries: []string{
			".direnv/",
			"result",
			"bin/",
			"dist/",
			"coverage.out",
			"*.test",
		},
	}, nil
}

func writeFileAtomic(path string, data []byte, perm os.FileMode) (err error) {
	dir := filepath.Dir(path)
	tempFile, err := os.CreateTemp(dir, ".dsqr-*")
	if err != nil {
		return err
	}

	tempName := tempFile.Name()
	defer func() {
		_ = tempFile.Close()
		if err != nil {
			_ = os.Remove(tempName)
		}
	}()

	if _, err = tempFile.Write(data); err != nil {
		return err
	}
	if err = tempFile.Chmod(perm); err != nil {
		return err
	}
	if err = tempFile.Close(); err != nil {
		return err
	}
	if err = os.Rename(tempName, path); err != nil {
		return err
	}
	return nil
}

func rollbackFiles(paths []string) {
	for _, path := range paths {
		_ = os.Remove(path)
	}
}

func renderTemplate(name, source string, data any) (string, error) {
	tmpl, err := template.New(name).Option("missingkey=error").Parse(source)
	if err != nil {
		return "", fmt.Errorf("failed to parse %s template: %w", name, err)
	}

	var out bytes.Buffer
	if err := tmpl.Execute(&out, data); err != nil {
		return "", fmt.Errorf("failed to render %s template: %w", name, err)
	}
	return out.String(), nil
}

func sortedKeys[K cmp.Ordered, V any](m map[K]V) []K {
	keys := make([]K, 0, len(m))
	for key := range m {
		keys = append(keys, key)
	}
	slices.Sort(keys)
	return keys
}

const envrcTemplate = `use flake
`

const gitignoreTemplate = `# Generated by dsqr
{{- range .GitignoreEntries }}
{{ . }}
{{- end }}
`

const flakeTemplate = `{
  description = "Bootstrapped project with Nix foundation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forEachSystem (
        system:
        let
          devConfig = import ./nix/devshell.nix { inherit nixpkgs system; };
        in
        devConfig.devShells.${system}
      );

      formatter = forEachSystem (
        system:
        (treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./nix/treefmt.nix).config.build.wrapper
      );

      checks = forEachSystem (system: {
        formatting =
          (treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./nix/treefmt.nix).config.build.check
            self;
      });

      packages = forEachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./nix/package.nix { };
      });

      apps = forEachSystem (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/{{ .BinaryName }}";
        };
      });
    };
}
`

const shellTemplate = `(import (
  let
    inherit ((builtins.fromJSON (builtins.readFile ./flake.lock)).nodes) flake-compat;
  in
  fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${flake-compat.locked.rev}.tar.gz";
    sha256 = flake-compat.locked.narHash;
  }
) { src = ./.; }).shellNix
`

const treefmtTemplate = `{
  projectRootFile = "flake.nix";
{{- range .TreefmtPrograms }}
  {{ . }}
{{- end }}
}
`

const devshellTemplate = `{ nixpkgs, system }:
let
  pkgs = import nixpkgs { inherit system; };
in
{
  devShells.${system}.default = pkgs.mkShell {
    packages = with pkgs; [
{{- range .DevPackages }}
      {{ . }}
{{- end }}
    ];

    shellHook = ''
      echo "{{ .ShellMessage }}"
    '';
  };
}
`

const goModTemplate = `module {{ .ModulePath }}

go 1.25
`

const goMainTemplate = `package main

import "fmt"

func message() string {
	return "{{ .Greeting }}"
}

func main() {
	fmt.Println(message())
}
`

const goMainTestTemplate = `package main

import "testing"

func TestMessage(t *testing.T) {
	if got, want := message(), "{{ .Greeting }}"; got != want {
		t.Fatalf("expected %q, got %q", want, got)
	}
}
`

const goPackageNixTemplate = `{
  lib,
  buildGoModule,
}:
let
  version = "0.1.0";
in
buildGoModule {
  pname = "{{ .BinaryName }}";
  inherit version;

  src = ../.;
  subPackages = [ "cmd/{{ .BinaryName }}" ];
  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "{{ .BinaryName }} CLI";
    license = licenses.mit;
    mainProgram = "{{ .BinaryName }}";
    platforms = platforms.unix;
  };
}
`
