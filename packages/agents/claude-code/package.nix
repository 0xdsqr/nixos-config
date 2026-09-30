{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.285";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-UfCb0eAh2fqKGGTBeXmb03yzmWKpN5NcXPaCM5jobbQ=";
    darwin-x64 = "sha256-JINffKS0M4wzrSHJijQC2cIvibgFUHXRiCjpeXOETsM=";
    linux-arm64 = "sha256-JPrHd0m+09kTZda2kVqkuCThQxjstrwXrbwZLwHJFz0=";
    linux-x64 = "sha256-M9rR7GFaLgjMeLSU8FwRDkmRbeLHnXjsh5nr9GsjPSk=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
