package commands

import (
	"context"
	"fmt"

	click "github.com/0xdsqr/go-click"
	"github.com/0xdsqr/moonshot/internal/host"
)

func Host() click.Command[RootOptions] {
	return click.Command[RootOptions]{
		Name:        "host",
		Description: "print host information",
		Usage:       "moonshot host",
		Run: func(ctx context.Context, env click.Env[RootOptions], args []string, pass []string) error {
			info := host.DetectHost()
			fmt.Println("os:", info.GOOS)
			fmt.Println("arch:", info.GOARCH)
			fmt.Println("nixos:", info.IsNixOS)
			return nil
		},
	}
}
