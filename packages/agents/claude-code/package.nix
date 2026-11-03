{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.317";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-CfFTtGtd+eizRUcW1oKpGQHeAgy8pjD2HewaAVsytek=";
    darwin-x64 = "sha256-AccUvH/r2wCPKOP2+ssdw35GpNj6jbWN8uKB7lHLMzw=";
    linux-arm64 = "sha256-VjoNYK0MIj2UFXaCEJl6yw9xNOpR3Dwjjoi8Lhjd7vo=";
    linux-x64 = "sha256-6yJEGeNEV1+qSh85spC2SUJaEM1e4u8dADSAzZrlfrA=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
