{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.295";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-ARbuLgpROQC2M9mVE2fxh0doZHjitGKAW4wxYJ8Ef3A=";
    darwin-x64 = "sha256-pgZkkiiFhaHvXkgssorSJxSrEs1I42fAzumIsAz/ckw=";
    linux-arm64 = "sha256-z7ncEzL7b5Kmg/g1gj6RsxeagDOYynhSzSOBo8sd6js=";
    linux-x64 = "sha256-RQO/4Rpsf8weCzm14NNHwEJI91CwOwl3s61rUx/m81g=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
