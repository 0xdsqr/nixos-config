{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.246";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-ewnwHLdqOODjp8R8XWmNOCFipf8mU4/HeGg3cMr5IYs=";
    darwin-x64 = "sha256-M2YlhQmGNxSH3n7Od21YPzbMOzvHF4/PveNlbQECifs=";
    linux-arm64 = "sha256-+YKW5uYcUHWJ0alzsmKXa3NHAOxOBVy2Sv2/bZozfbc=";
    linux-x64 = "sha256-GgpmLcG7k46uw4VFq86aSmkRPX1/fF4aVT6idmF7kGo=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
