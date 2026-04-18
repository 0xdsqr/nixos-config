package commands

import (
	"context"
	"encoding/json"
	"fmt"

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
		Description: "print the rebuild command for this host",
		Usage:       "moonshot host rebuild",
		Run: func(ctx context.Context, env click.Env[Root], args []string, pass []string) error {
			if len(args) > 0 {
				return fmt.Errorf("host rebuild does not accept arguments")
			}

			command, err := rebuildCommand(env.Root.HostInfo)
			if err != nil {
				return err
			}

			_, err = fmt.Fprintln(env.Stdout, command)
			return err
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

func rebuildCommand(info hostinfo.HostInfo) (string, error) {
	hostname := info.Hostname
	if hostname == "" {
		return "", fmt.Errorf("host rebuild requires a hostname")
	}

	switch {
	case info.Platform.IsDarwin:
		return fmt.Sprintf("darwin-rebuild switch --flake .#%s", hostname), nil
	case info.Platform.IsLinux:
		return fmt.Sprintf("sudo nixos-rebuild switch --flake .#%s", hostname), nil
	default:
		return "", fmt.Errorf("host rebuild is only supported on Darwin and Linux hosts")
	}
}
