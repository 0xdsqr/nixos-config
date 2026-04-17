package app

import (
	"context"

	click "github.com/0xdsqr/go-click"
	"github.com/0xdsqr/moonshot/internal/commands"
	"github.com/0xdsqr/moonshot/internal/host"
)

func Run(args []string) error {
	app := click.App[commands.Root]{
		Name: "moonshot",
		ConfigureRoot: func(root *commands.Root) {
			root.Host = host.DetectHost()
		},
		Commands: []click.Command[commands.Root]{
			commands.Version(),
			commands.Host(),
		},
	}
	return app.Run(context.Background(), args)
}
