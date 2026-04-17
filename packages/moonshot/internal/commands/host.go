package commands

import (
	"context"
	"fmt"

	click "github.com/0xdsqr/go-click"
)

func Host() click.Command[Root] {
	return click.Command[Root]{
		Name:        "host",
		Description: "print host information",
		Usage:       "moonshot host",
		Run: func(ctx context.Context, env click.Env[Root], args []string, pass []string) error {
			info := env.Root.Host
			fmt.Fprintln(env.Stdout, "os:", info.GOOS)
			fmt.Fprintln(env.Stdout, "arch:", info.GOARCH)
			fmt.Fprintln(env.Stdout, "nixos:", info.IsNixOS)
			return nil
		},
	}
}
