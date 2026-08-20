{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.237";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-M4kBNR1P8XSVc4xn/D4SoywbUGc4rF4BLreC09i1vkM=";
    darwin-x64 = "sha256-nwB4l1SnuV/rxtTjejtlI9TZxMIzOizkvVlq2CGGIk4=";
    linux-arm64 = "sha256-pwHPtrtHA6vG885HUIyHjKgVjr2+rNXDXH1RDHvHAXc=";
    linux-x64 = "sha256-c5dRZ/AQhpPPb9ZhSZR4FlfruEVuvvXSR0WHNKv7ORY=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
