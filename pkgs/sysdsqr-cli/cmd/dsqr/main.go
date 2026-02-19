package main

import (
	"fmt"
	"os"

	"github.com/0xdsqr/sysdsqr/internal/cli"
)

var version = "dev"

func main() {
	app := cli.New(version, os.Stdout)
	if err := app.Run(os.Args); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
