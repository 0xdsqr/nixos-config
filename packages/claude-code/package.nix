{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.210";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-G0cdYtERdIJonXVEf14FDGQNpxelo8kebBN5JFD4xmI=";
    darwin-x64 = "sha256-iS8sh4BQ2IKeZxGTKN2XaDRfuhiljBaSErcFl8kXXEA=";
    linux-arm64 = "sha256-hP6xk8HZHzteuoNu1HwOTe6VMZWrupUJF8PhAe/xdOg=";
    linux-x64 = "sha256-59LOtT7Uws7R/n/BxjMcmNxfe0ybJyLZxfo91d/29xk=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
