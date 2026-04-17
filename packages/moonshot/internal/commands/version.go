package commands

import (
	"context"
	"fmt"

	click "github.com/0xdsqr/go-click"
	"github.com/0xdsqr/moonshot/internal/version"
)

func Version() click.Command[RootOptions] {
	return click.Command[RootOptions]{
		Name:        "version",
		Description: "print the CLI version",
		Usage:       "sys-dsqr version",
		Run: func(ctx context.Context, env click.Env[RootOptions], args []string, pass []string) error {
			_, err := fmt.Fprintln(env.Stdout, version.Get())
			return err
		},
	}
}
