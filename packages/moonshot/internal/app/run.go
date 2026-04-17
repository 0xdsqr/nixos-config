package app

import (
	"context"

	click "github.com/0xdsqr/go-click"
	"github.com/0xdsqr/moonshot/internal/commands"
)

func Run(args []string) error {
	app := click.App[commands.RootOptions]{
		Name: "moonshot",
		Commands: []click.Command[commands.RootOptions]{
			commands.Version(),
			commands.Host(),
		},
	}
	return app.Run(context.Background(), args)
}
