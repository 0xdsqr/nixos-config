package scaffold

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestParseRuntime(t *testing.T) {
	tests := []struct {
		in      string
		want    Runtime
		wantErr bool
	}{
		{in: "go", want: RuntimeGo},
		{in: "golang", want: RuntimeGo},
		{in: "ts", wantErr: true},
		{in: "typescript", wantErr: true},
		{in: "python", wantErr: true},
	}

	for _, tc := range tests {
		got, err := ParseRuntime(tc.in)
		if tc.wantErr {
			if err == nil {
				t.Fatalf("expected error for %q", tc.in)
			}
			continue
		}
		if err != nil {
			t.Fatalf("unexpected error for %q: %v", tc.in, err)
		}
		if got != tc.want {
			t.Fatalf("expected %q, got %q", tc.want, got)
		}
	}
}

func TestBootstrapRepoGo(t *testing.T) {
	target := filepath.Join(t.TempDir(), "hello-go")
	created, err := BootstrapRepo(target, RuntimeGo)
	if err != nil {
		t.Fatalf("BootstrapRepo returned error: %v", err)
	}
	if len(created) != 10 {
		t.Fatalf("expected 10 files, got %d", len(created))
	}

	assertFileContains(t, filepath.Join(target, "flake.nix"), "nixos-unstable")
	assertFileContains(t, filepath.Join(target, ".envrc"), "use flake")
	assertFileContains(t, filepath.Join(target, ".gitignore"), "coverage.out")
	assertFileContains(t, filepath.Join(target, "go.mod"), "module github.com/your-org/hello-go")
	assertFileContains(t, filepath.Join(target, "nix/package.nix"), "subPackages = [ \"cmd/hello-go\" ]")
	assertFileContains(t, filepath.Join(target, "cmd/hello-go/main.go"), "hello from hello-go")
	assertFileContains(t, filepath.Join(target, "cmd/hello-go/main_test.go"), "TestMessage")
	assertFileContains(t, filepath.Join(target, "nix/devshell.nix"), "go")
	assertFileContains(t, filepath.Join(target, "nix/treefmt.nix"), "programs.gofmt.enable = true;")
}

func TestBootstrapRepoNoOverwrite(t *testing.T) {
	target := t.TempDir()
	if err := os.WriteFile(filepath.Join(target, "flake.nix"), []byte("existing"), 0o644); err != nil {
		t.Fatalf("failed to pre-create file: %v", err)
	}

	_, err := BootstrapRepo(target, RuntimeGo)
	if err == nil {
		t.Fatal("expected overwrite error")
	}
	if !strings.Contains(err.Error(), "refusing to overwrite existing file") {
		t.Fatalf("unexpected error: %v", err)
	}
	if _, statErr := os.Stat(filepath.Join(target, ".envrc")); !errors.Is(statErr, os.ErrNotExist) {
		t.Fatalf("expected .envrc to not be written after preflight failure, got: %v", statErr)
	}
}

func TestBootstrapRepoRollbackOnWriteFailure(t *testing.T) {
	target := t.TempDir()
	nixDir := filepath.Join(target, "nix")
	if err := os.MkdirAll(nixDir, 0o755); err != nil {
		t.Fatalf("failed to create nix dir: %v", err)
	}
	if err := os.Chmod(nixDir, 0o500); err != nil {
		t.Fatalf("failed to chmod nix dir: %v", err)
	}
	t.Cleanup(func() {
		_ = os.Chmod(nixDir, 0o755)
	})

	_, err := BootstrapRepo(target, RuntimeGo)
	if err == nil {
		t.Fatal("expected write failure")
	}
	if _, statErr := os.Stat(filepath.Join(target, ".envrc")); !errors.Is(statErr, os.ErrNotExist) {
		t.Fatalf("expected rollback to remove .envrc, got: %v", statErr)
	}
	if _, statErr := os.Stat(filepath.Join(target, "flake.nix")); !errors.Is(statErr, os.ErrNotExist) {
		t.Fatalf("expected rollback to remove flake.nix, got: %v", statErr)
	}
}

func assertFileContains(t *testing.T, path, needle string) {
	t.Helper()

	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read %s: %v", path, err)
	}
	if !strings.Contains(string(data), needle) {
		t.Fatalf("file %s did not contain expected text %q", path, needle)
	}
}
