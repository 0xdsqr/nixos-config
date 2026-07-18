{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.214";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-WXlt0Y6dd/ElbzZ9ttKM5L2c1ZaOQCrToyeqw2q8bew=";
    darwin-x64 = "sha256-2Xm6FWYoKJaeXQ858TZ3mKB+9uAxtSTv2tN/58r4QBA=";
    linux-arm64 = "sha256-TDjyalekJhnugT8V3Dn8H6T+C7QDIVw83DQrWPponDw=";
    linux-x64 = "sha256-PAKRNvfIH1TtSjjp1S5lWq1TZDPbveUFGcjDG7ZGrRQ=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
