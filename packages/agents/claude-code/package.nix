{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.301";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-HwTGnhwk5NCnFqhjrwqtj8ZNSaSZM0wpcB8HNwAna5k=";
    darwin-x64 = "sha256-NDlCe/zpYv3c9VfFoFjKkU+mPgb+6JT44So/EOBNGHE=";
    linux-arm64 = "sha256-HhGQNqgC01m6X5iGQo4DFYboeW96hY1ajuF5rHuGBPA=";
    linux-x64 = "sha256-vBqtmYLHtZx9iJ/5JZXWHPRuCm6uB0y1UdkyqYm80iI=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
