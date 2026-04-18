package hostinfo

import (
	"runtime"
)

type PlatformInfo struct {
	GOOS     string `json:"goos"`
	GOARCH   string `json:"goarch"`
	IsLinux  bool   `json:"is_linux"`
	IsDarwin bool   `json:"is_darwin"`
	IsNixOS  bool   `json:"is_nixos"`
}

type NixInfo struct {
	Installed     bool   `json:"installed"`
	BinaryPath    string `json:"binary_path,omitempty"`
	Version       string `json:"version,omitempty"`
	Determinate   bool   `json:"determinate"`
	StoreDirFound bool   `json:"store_dir_found"`
	VarDirFound   bool   `json:"var_dir_found"`
}

type HostInfo struct {
	Platform PlatformInfo `json:"platform"`
	Nix      NixInfo      `json:"nix"`
}

func Get() HostInfo {
	platform := PlatformInfo{
		GOOS:     runtime.GOOS,
		GOARCH:   runtime.GOARCH,
		IsLinux:  runtime.GOOS == "linux",
		IsDarwin: runtime.GOOS == "darwin",
	}
	return HostInfo{
		Platform: platform,
	}
}
