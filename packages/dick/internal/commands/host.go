package commands

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	click "github.com/0xdsqr/go-click"
	"github.com/0xdsqr/dick/internal/hostinfo"
)

func Host() click.Command[Root] {
	return click.Command[Root]{
		Name:        "host",
		Description: "inspect host information",
		Usage:       "dick host",
		Commands: []click.Command[Root]{
			hostInfo(),
			hostRebuild(),
		},
	}
}

func hostInfo() click.Command[Root] {
	return click.Command[Root]{
		Name:        "info",
		Description: "print host information as JSON",
		Usage:       "dick host info",
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
	var name string

	return click.Command[Root]{
		Name:        "rebuild",
		Description: "run the rebuild for this host (Linux only for now)",
		Usage:       "dick host rebuild [--name HOST]",
		ConfigureFlags: func(fs *flag.FlagSet) {
			fs.StringVar(&name, "name", "", "override the flake host name to rebuild")
			fs.StringVar(&name, "n", "", "override the flake host name to rebuild")
		},
		Run: func(ctx context.Context, env click.Env[Root], args []string, pass []string) error {
			if len(args) > 0 {
				return fmt.Errorf("host rebuild does not accept positional arguments")
			}

			info := env.Root.HostInfo
			hostname, err := resolveRebuildHostName(info, name)
			if err != nil {
				return err
			}

			switch {
			case info.Platform.IsDarwin:
				_, err := fmt.Fprintln(env.Stdout, "darwin rebuild coming soon")
				return err
			case info.Platform.IsLinux:
				return runLinuxRebuild(ctx, env, hostname)
			default:
				return fmt.Errorf("host rebuild is only supported on Darwin and Linux hosts")
			}
		},
	}
}

func runLinuxRebuild(ctx context.Context, env click.Env[Root], hostname string) error {
	flakeRef, flakeDir, err := linuxRebuildTarget(hostname)
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

func resolveRebuildHostName(info hostinfo.HostInfo, override string) (string, error) {
	if override != "" {
		return override, nil
	}

	hostname := info.Hostname
	if hostname == "" {
		return "", fmt.Errorf("host rebuild requires --name/-n when the machine hostname is unavailable")
	}

	return hostname, nil
}

func linuxRebuildTarget(hostname string) (string, string, error) {
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
