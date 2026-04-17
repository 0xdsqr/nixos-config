package main

import (
	"fmt"
	"os"

	"github.com/0xdsqr/moonshot/internal/app"
)

func main() {
	if err := app.Run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}
