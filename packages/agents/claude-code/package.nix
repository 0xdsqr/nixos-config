{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.316";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-ZMMn6SssXg94wKmAxaUYEh4fDRQMp3HKXdRIjRotyz8=";
    darwin-x64 = "sha256-ID0i+6/aufawzali7Fc+MquXCJTGOx37BAk3jyi5w0Q=";
    linux-arm64 = "sha256-Vc244WLRkEMmlupUAQ4Pyi4Y0G+npxJ/1WO5/9TyJiQ=";
    linux-x64 = "sha256-/RPHAAD+w/IRbfvLthISELSikyi/DkYhClndWUpn2CQ=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
