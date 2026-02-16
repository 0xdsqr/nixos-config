package main

import (
	"fmt"
	"os"
	"runtime"
)

const version = "0.1.0"

func main() {
	if len(os.Args) < 2 {
		printHelp()
		return
	}

	switch os.Args[1] {
	case "version", "-v", "--version":
		printVersion()
	case "info":
		printInfo()
	case "help", "-h", "--help":
		printHelp()
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", os.Args[1])
		printHelp()
		os.Exit(1)
	}
}

func printVersion() {
	fmt.Printf("sysdsqr %s\n", version)
}

func printInfo() {
	hostname, _ := os.Hostname()
	cwd, _ := os.Getwd()

	fmt.Println("System Information")
	fmt.Println("==================")
	fmt.Printf("Version:    %s\n", version)
	fmt.Printf("Hostname:   %s\n", hostname)
	fmt.Printf("OS:         %s\n", runtime.GOOS)
	fmt.Printf("Arch:       %s\n", runtime.GOARCH)
	fmt.Printf("Go Version: %s\n", runtime.Version())
	fmt.Printf("CWD:        %s\n", cwd)
}

func printHelp() {
	fmt.Println("sysdsqr - System admin CLI for dsqr homelab")
	fmt.Println()
	fmt.Println("Usage: sysdsqr <command>")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  version    Print version information")
	fmt.Println("  info       Print system information")
	fmt.Println("  help       Print this help message")
}
