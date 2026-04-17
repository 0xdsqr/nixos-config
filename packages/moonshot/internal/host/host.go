package host

import (
	"runtime"
)

type HostInfo struct {
	GOOS    string
	GOARCH  string
	IsNixOS bool
}

func DetectHost() HostInfo {
	return HostInfo{
		GOOS:    runtime.GOOS,
		GOARCH:  runtime.GOARCH,
		IsNixOS: detectNixOS(),
	}
}

func detectNixOS() bool {
	return true
}
