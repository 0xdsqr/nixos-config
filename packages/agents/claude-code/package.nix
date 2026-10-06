{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.291";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-mh0u1rtEIej8gMiSwEE/KTvj7lCuPX3aGnYiGXoFZpA=";
    darwin-x64 = "sha256-Ijv03g6POMslT8OPgv2gn5/P1OKqxitZ735/GWCkXd0=";
    linux-arm64 = "sha256-wYRzoEzE8HdDXV2QgfCevqRuaZ6yglzqZHQcS8y4dkc=";
    linux-x64 = "sha256-B4+tKNApfJol0wa2NbLYgWxoOTR1IPKetU/+pdVhQvs=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
