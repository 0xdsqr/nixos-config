package main

import (
	"os"
	"runtime"
	"testing"
)

func TestVersion(t *testing.T) {
	if version == "" {
		t.Error("version should not be empty")
	}
	if version != "0.1.0" {
		t.Errorf("expected version 0.1.0, got %s", version)
	}
}

func TestGetHostname(t *testing.T) {
	hostname, err := os.Hostname()
	if err != nil {
		t.Errorf("failed to get hostname: %v", err)
	}
	if hostname == "" {
		t.Error("hostname should not be empty")
	}
}

func TestRuntime(t *testing.T) {
	if runtime.GOOS == "" {
		t.Error("GOOS should not be empty")
	}
	if runtime.GOARCH == "" {
		t.Error("GOARCH should not be empty")
	}
}
