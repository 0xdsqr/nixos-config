{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.303";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-0to7AD3Ai4i3IwRpAU/j4dxv6UvI9kjomzQXXTAmk3A=";
    darwin-x64 = "sha256-bF1jtDVoxdYJY9QPBbAIfLA7pEqQdA0nrcUF9BV4Bts=";
    linux-arm64 = "sha256-84T0mCYzbUrASErGrJ2NFvZNJE0YbOIny9fMCIwDMV0=";
    linux-x64 = "sha256-N1mI9Fd1ZSQjRpXPLY9krOmcX2hoLkfqJIYqhDwZFFA=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
