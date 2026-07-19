{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.215";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-kGCLXFq1BOludzZc6mID0EbikdWbK7Qs8o3LLM353Vg=";
    darwin-x64 = "sha256-HvX15W7en3dlqb72VOzmBF26WPSLf1tpl2U3WVPVK2s=";
    linux-arm64 = "sha256-K0Oj1bB4chfl1zgfrULHMUKSVG/p2564ubN53pBQmzA=";
    linux-x64 = "sha256-we//qvNwqhh8tqCd2T1OURxkaJmwB4R2+DeRtmS95/4=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
