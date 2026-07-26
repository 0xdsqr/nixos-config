{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.220";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-it3IV/P+ZNWgNor57lAyG1CvtKaRi6PvAYq4T1274IE=";
    darwin-x64 = "sha256-3Ke+CqfT2SSDbUQODG2OPUfvPI5h+lgJtUuQFxcM4vM=";
    linux-arm64 = "sha256-FZ5KUdeW878UZ3V3EA9++4RWEbHOrwwwy9jUZQ2UIYU=";
    linux-x64 = "sha256-Z09h8g/zBvMQDPkgDkw2xLcCeLW+8ohFSYGblCqJyGM=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
