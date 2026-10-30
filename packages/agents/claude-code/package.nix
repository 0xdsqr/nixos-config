{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.314";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-Idbnuabwe0z8t98Tdgs7cqol4IThOlNUQTOCmHuoMu0=";
    darwin-x64 = "sha256-QEd5owijWOzsiyXIvM8M55qUzyYdEst0BlUY0YnBdPg=";
    linux-arm64 = "sha256-pmwKj10Mh6Q5lT15eYUZK7y677zi4Ney6qjfMO8PPvI=";
    linux-x64 = "sha256-RIcEK0xPXYjUVo9orpiq4LH/rliGTPV/uGhkG8X4RZQ=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
