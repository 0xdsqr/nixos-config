{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.309";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-Xq3AAJzc28DQblgRDXsrr4jO1giLHDOmCiEhf+QQYZw=";
    darwin-x64 = "sha256-IA4Nd1rlXAQNs7uNuN4+Iu/N29fgq/9atQ3RD2hTQl0=";
    linux-arm64 = "sha256-l5bdJomTN/aHc5oLOac1O2OfBio0Nqe5Qfzxmht1eps=";
    linux-x64 = "sha256-TXBKiuy+A4r/owAPSYrhfBtPdTrdj6y4dkEgr/yZtlg=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
