package app

import (
	"context"

	click "github.com/0xdsqr/go-click"
	"github.com/0xdsqr/dick/internal/commands"
	"github.com/0xdsqr/dick/internal/hostinfo"
)

func Run(args []string) error {
	app := click.App[commands.Root]{
		Name: "dick",
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
