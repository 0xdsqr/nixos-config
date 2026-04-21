package commands

import (
	"context"
	"fmt"

	click "github.com/0xdsqr/go-click"
	"github.com/0xdsqr/dick/internal/version"
)

func Version() click.Command[Root] {
	return click.Command[Root]{
		Name:        "version",
		Description: "print the CLI version",
		Usage:       "dick version",
		Run: func(ctx context.Context, env click.Env[Root], args []string, pass []string) error {
			_, err := fmt.Fprintln(env.Stdout, version.Value)
			return err
		},
	}
}
