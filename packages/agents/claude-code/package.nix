{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.280";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-OHpcXc27gVCF7fC695WR+diJTv6SK86vPXWxsIBVIp0=";
    darwin-x64 = "sha256-wdMth2MEgiUGMyCKt3hVQpskAQrjCGp/91ObV7kxaNQ=";
    linux-arm64 = "sha256-kvK0/QXQvc97mg1ODs70oeSzaLKQzY/QfP+aUAE/RaI=";
    linux-x64 = "sha256-HghQPb3zwssNcG0y80CCdziNHHbvEIZz6P5CwbMikls=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
