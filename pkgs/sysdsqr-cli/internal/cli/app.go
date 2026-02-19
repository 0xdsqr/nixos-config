package cli

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"

	"github.com/0xdsqr/sysdsqr/internal/scaffold"
)

type App struct {
	version string
	out     io.Writer
}

func New(version string, out io.Writer) *App {
	if version == "" {
		version = "dev"
	}
	return &App{
		version: version,
		out:     out,
	}
}

func (a *App) Run(argv []string) error {
	name := binaryName(argv)
	if len(argv) < 2 {
		a.printHelp(name)
		return nil
	}

	switch argv[1] {
	case "version", "-v", "--version":
		fmt.Fprintf(a.out, "%s %s\n", name, a.version)
		return nil
	case "info":
		a.printInfo()
		return nil
	case "new":
		return a.runNew(name, argv[2:])
	case "help", "-h", "--help":
		a.printHelp(name)
		return nil
	default:
		return fmt.Errorf("unknown command: %s", argv[1])
	}
}

func (a *App) runNew(name string, args []string) error {
	runtimeKind, targetPath, err := parseNewRepoArgs(name, args)
	if err != nil {
		return err
	}

	created, err := scaffold.BootstrapRepo(targetPath, runtimeKind)
	if err != nil {
		return err
	}

	fmt.Fprintf(a.out, "Bootstrapped %s repo in %s\n", runtimeKind, targetPath)
	fmt.Fprintln(a.out, "Created files:")
	for _, path := range created {
		fmt.Fprintf(a.out, "  - %s\n", path)
	}
	return nil
}

func (a *App) printInfo() {
	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}

	cwd, err := os.Getwd()
	if err != nil {
		cwd = "unknown"
	}

	fmt.Fprintln(a.out, "System Information")
	fmt.Fprintln(a.out, "==================")
	fmt.Fprintf(a.out, "Version:    %s\n", a.version)
	fmt.Fprintf(a.out, "Hostname:   %s\n", hostname)
	fmt.Fprintf(a.out, "OS:         %s\n", runtime.GOOS)
	fmt.Fprintf(a.out, "Arch:       %s\n", runtime.GOARCH)
	fmt.Fprintf(a.out, "Go Version: %s\n", runtime.Version())
	fmt.Fprintf(a.out, "CWD:        %s\n", cwd)
}

func (a *App) printHelp(name string) {
	fmt.Fprintf(a.out, "%s - System admin CLI for dsqr homelab\n", name)
	fmt.Fprintln(a.out)
	fmt.Fprintf(a.out, "Usage: %s <command>\n", name)
	fmt.Fprintln(a.out)
	fmt.Fprintln(a.out, "Commands:")
	fmt.Fprintln(a.out, "  version    Print version information")
	fmt.Fprintln(a.out, "  info       Print system information")
	fmt.Fprintln(a.out, "  new go repo [path]   (preferred)")
	fmt.Fprintln(a.out, "  new repo go [path]   (compat)")
	fmt.Fprintln(a.out, "  help       Print this help message")
}

func parseNewRepoArgs(binaryName string, args []string) (scaffold.Runtime, string, error) {
	if len(args) < 2 {
		return "", "", fmt.Errorf("usage: %s new go repo [path]", binaryName)
	}

	var runtimeToken string
	pathIndex := 2

	switch {
	case args[0] == "repo":
		runtimeToken = args[1]
	case args[1] == "repo":
		runtimeToken = args[0]
	default:
		return "", "", fmt.Errorf("usage: %s new go repo [path]", binaryName)
	}

	if len(args) > pathIndex+1 {
		return "", "", fmt.Errorf("too many arguments for new repo")
	}

	runtimeKind, err := scaffold.ParseRuntime(runtimeToken)
	if err != nil {
		return "", "", err
	}

	targetPath := "."
	if len(args) > pathIndex {
		targetPath = args[pathIndex]
	}
	return runtimeKind, targetPath, nil
}

func binaryName(argv []string) string {
	if len(argv) == 0 {
		return "dsqr"
	}
	name := filepath.Base(argv[0])
	if name == "" {
		return "dsqr"
	}
	return name
}
