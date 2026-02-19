package cli

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRunVersion(t *testing.T) {
	stdout := &bytes.Buffer{}
	app := New("1.2.3", stdout)

	if err := app.Run([]string{"dsqr", "version"}); err != nil {
		t.Fatalf("Run returned error: %v", err)
	}

	if got := stdout.String(); got != "dsqr 1.2.3\n" {
		t.Fatalf("unexpected output: %q", got)
	}
}

func TestRunNewRepo(t *testing.T) {
	stdout := &bytes.Buffer{}
	app := New("dev", stdout)

	target := filepath.Join(t.TempDir(), "repo")
	if err := app.Run([]string{"dsqr", "new", "go", "repo", target}); err != nil {
		t.Fatalf("Run returned error: %v", err)
	}

	if _, err := os.Stat(filepath.Join(target, "flake.nix")); err != nil {
		t.Fatalf("expected scaffolded flake.nix: %v", err)
	}
	if !strings.Contains(stdout.String(), "Bootstrapped go repo") {
		t.Fatalf("expected success output, got: %q", stdout.String())
	}
}

func TestRunNewRepoCompatOrder(t *testing.T) {
	stdout := &bytes.Buffer{}
	app := New("dev", stdout)

	target := filepath.Join(t.TempDir(), "repo-compat")
	if err := app.Run([]string{"dsqr", "new", "repo", "go", target}); err != nil {
		t.Fatalf("Run returned error: %v", err)
	}

	if _, err := os.Stat(filepath.Join(target, "flake.nix")); err != nil {
		t.Fatalf("expected scaffolded flake.nix: %v", err)
	}
}

func TestRunUnknownCommand(t *testing.T) {
	app := New("dev", &bytes.Buffer{})
	err := app.Run([]string{"dsqr", "wat"})
	if err == nil {
		t.Fatal("expected error for unknown command")
	}
	if !strings.Contains(err.Error(), "unknown command") {
		t.Fatalf("unexpected error: %v", err)
	}
}
