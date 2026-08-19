{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.235";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-g7j4Bvby7qMWz+JGYo5sIzdHEdho8f0ECdtVG4d7d0g=";
    darwin-x64 = "sha256-MlotvBZrqDYakTzliNzkojZ4lQIGAjms6lIHK7UaVPE=";
    linux-arm64 = "sha256-z/lZL6opLbD2rCGHTxUbjD1E4jvwq5/RvMqV7cNGlUk=";
    linux-x64 = "sha256-v88K4tv5SytqEGB0qr85OLmhCInDtnjky1oAwDJ01dU=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
