package commands

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	click "github.com/0xdsqr/go-click"
	"github.com/0xdsqr/moonshot/internal/hostinfo"
)

func Host() click.Command[Root] {
	subcommands := []click.Command[Root]{
		hostInfo(),
		hostRebuild(),
	}

	return click.Command[Root]{
		Name:        "host",
		Description: "inspect host information",
		Usage:       "moonshot host",
		Commands:    subcommands,
		Run: func(ctx context.Context, env click.Env[Root], args []string, pass []string) error {
			if len(args) > 0 {
				return fmt.Errorf("host does not accept arguments")
			}

			return printHostHelp(env, subcommands)
		},
	}
}

func hostInfo() click.Command[Root] {
	return click.Command[Root]{
		Name:        "info",
		Description: "print host information as JSON",
		Usage:       "moonshot host info",
		Run: func(ctx context.Context, env click.Env[Root], args []string, pass []string) error {
			if len(args) > 0 {
				return fmt.Errorf("host info does not accept arguments")
			}

			info := env.Root.HostInfo
			payload, err := json.MarshalIndent(info, "", "  ")
			if err != nil {
				return fmt.Errorf("marshal host info: %w", err)
			}

			_, err = fmt.Fprintln(env.Stdout, string(payload))
			return err
		},
	}
}

func hostRebuild() click.Command[Root] {
	return click.Command[Root]{
		Name:        "rebuild",
		Description: "run the rebuild for this host (Linux only for now)",
		Usage:       "moonshot host rebuild",
		Run: func(ctx context.Context, env click.Env[Root], args []string, pass []string) error {
			if len(args) > 0 {
				return fmt.Errorf("host rebuild does not accept arguments")
			}

			info := env.Root.HostInfo

			switch {
			case info.Platform.IsDarwin:
				_, err := fmt.Fprintln(env.Stdout, "darwin rebuild coming soon")
				return err
			case info.Platform.IsLinux:
				return runLinuxRebuild(ctx, env, info)
			default:
				return fmt.Errorf("host rebuild is only supported on Darwin and Linux hosts")
			}
		},
	}
}

func printHostHelp(env click.Env[Root], commands []click.Command[Root]) error {
	if _, err := fmt.Fprintln(env.Stdout, "Available commands:"); err != nil {
		return err
	}

	for _, cmd := range commands {
		if _, err := fmt.Fprintf(env.Stdout, "  %s\t%s\n", cmd.Name, cmd.Description); err != nil {
			return err
		}
	}

	return nil
}

func runLinuxRebuild(ctx context.Context, env click.Env[Root], info hostinfo.HostInfo) error {
	flakeRef, flakeDir, err := linuxRebuildTarget(info)
	if err != nil {
		return err
	}

	cmd := exec.CommandContext(ctx, "sudo", "nixos-rebuild", "switch", "--flake", flakeRef)
	cmd.Dir = flakeDir
	cmd.Stdin = os.Stdin
	cmd.Stdout = env.Stdout
	cmd.Stderr = env.Stderr

	return cmd.Run()
}

func linuxRebuildTarget(info hostinfo.HostInfo) (string, string, error) {
	hostname := info.Hostname
	if hostname == "" {
		return "", "", fmt.Errorf("host rebuild requires a hostname")
	}

	wd, err := os.Getwd()
	if err != nil {
		return "", "", fmt.Errorf("get working directory: %w", err)
	}

	flakeDir, err := findFlakeDir(wd)
	if err != nil {
		return "", "", err
	}

	return fmt.Sprintf("%s#%s", flakeDir, hostname), flakeDir, nil
}

func findFlakeDir(start string) (string, error) {
	dir := filepath.Clean(start)

	for {
		flakePath := filepath.Join(dir, "flake.nix")
		if _, err := os.Stat(flakePath); err == nil {
			return dir, nil
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			return "", fmt.Errorf("could not find flake.nix from %s", start)
		}

		dir = parent
	}
}
