{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.239";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-K096r9qmW8wjNfVqSydjF4NyA/LFWHsfKhfKeK0U428=";
    darwin-x64 = "sha256-F0Jv1j5myw366uNHY+GDaFWkRIUPElbE6Urn1tIoC6c=";
    linux-arm64 = "sha256-ZvICybUqEzGKp9VeGAEw+5XO0Er23Eb9HqgjtZjzVVY=";
    linux-x64 = "sha256-feGxV24uC+c86RwrTe3xakEFjqYzuVejb9xgRN38Dzw=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
