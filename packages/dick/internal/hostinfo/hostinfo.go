package hostinfo

import (
	"bufio"
	"os"
	"os/exec"
	"runtime"
	"strings"
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
	Hostname string       `json:"hostname,omitempty"`
	Platform PlatformInfo `json:"platform"`
	Nix      NixInfo      `json:"nix"`
}

func Get() HostInfo {
	hostname, _ := os.Hostname()

	platform := PlatformInfo{
		GOOS:     runtime.GOOS,
		GOARCH:   runtime.GOARCH,
		IsLinux:  runtime.GOOS == "linux",
		IsDarwin: runtime.GOOS == "darwin",
	}

	if platform.IsLinux {
		platform.IsNixOS = detectNixOS()
	}

	return HostInfo{
		Hostname: hostname,
		Platform: platform,
		Nix:      detectNixInfo(),
	}
}

func detectNixInfo() NixInfo {
	info := NixInfo{
		StoreDirFound: pathExists("/nix/store"),
		VarDirFound:   pathExists("/nix/var"),
	}

	path, err := exec.LookPath("nix")
	if err != nil {
		return info
	}

	info.Installed = true
	info.BinaryPath = path
	info.Version = detectNixVersion(path)
	info.Determinate = strings.Contains(strings.ToLower(info.Version), "determinate")

	return info
}

func detectNixOS() bool {
	f, err := os.Open("/etc/os-release")
	if err != nil {
		return false
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "ID=") {
			v := strings.TrimPrefix(line, "ID=")
			v = strings.Trim(v, `"`)
			return v == "nixos"
		}
	}

	return false
}

func detectNixVersion(path string) string {
	out, err := exec.Command(path, "--version").Output()
	if err != nil {
		return ""
	}

	return strings.TrimSpace(string(out))
}

func pathExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
