{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.204";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-Fne2dZW2JRFW1iYA3IXUBw7Dhbct0LB+c3QqVgMJUsM=";
    darwin-x64 = "sha256-nM6l8Z7ARi87mD/zQAqXra8WqDw9w2ppuRaAXyvIyCk=";
    linux-arm64 = "sha256-w3JWqMOZi4Z16DhfGuRnfWm9/x5xfDiSlu7HDgLjF+8=";
    linux-x64 = "sha256-yO4eppFUUzxpGmj0artkUZb+cznSbm/CBMx/CCIBOdM=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
