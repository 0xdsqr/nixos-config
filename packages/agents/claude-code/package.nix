{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.306";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-tdeVt3YAMteZVLVanNGHbc86jclgj9a7n2GFk/af1Es=";
    darwin-x64 = "sha256-/Cc/TKrrERib/tgiUUlnKM8eZQVjy5tfcNkexr7ELBc=";
    linux-arm64 = "sha256-d9JX1ei4cw7GHVpJkqjrZVUKr5WJ9GSYiqGpaEM42AE=";
    linux-x64 = "sha256-UgvGwfQK9Ga9A6J4ta4a8aKTi8feW55csVUm2iDXHP4=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
