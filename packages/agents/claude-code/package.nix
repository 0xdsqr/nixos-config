{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.278";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-vSRWYvuKDjIbO/Ez6TA3HWVjw4dSeIXzCyYTrvO6FNY=";
    darwin-x64 = "sha256-xSJCXj1CJ10qwiOHV++Lp/gNFlqTQETsWnpf19e5lQs=";
    linux-arm64 = "sha256-febKsTTkgyEUjjAYLJhhQRjo9GZoGUEr6tRYZRkLNO0=";
    linux-x64 = "sha256-XEc1k3hE6E+KkzBuhBpbDhIlKQmweHD3ibGQRo2hR6s=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
