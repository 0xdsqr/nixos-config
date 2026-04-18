package app

import (
	"context"

	click "github.com/0xdsqr/go-click"
	"github.com/0xdsqr/moonshot/internal/commands"
	"github.com/0xdsqr/moonshot/internal/hostinfo"
)

func Run(args []string) error {
	app := click.App[commands.Root]{
		Name: "moonshot",
		ConfigureRoot: func(root *commands.Root) {
			root.HostInfo = hostinfo.Get()
		},
		Commands: []click.Command[commands.Root]{
			commands.Version(),
			commands.Host(),
		},
	}
	return app.Run(context.Background(), args)
}
