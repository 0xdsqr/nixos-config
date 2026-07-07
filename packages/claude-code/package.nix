{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.202";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-dBT3B4YeL+Wv7zOkZviIqNIXDlAo9enShY8dPvRf/KU=";
    darwin-x64 = "sha256-DcV4uylAlPUEHpmgREAwrGrnI2s4flbwDUpSFIFnY70=";
    linux-arm64 = "sha256-3l4Lso4rMkCURO1MFDHikxABwF7ScKPclsZwawaThn8=";
    linux-x64 = "sha256-cVkCAiSYkts4BezVuGf4MfBLgSnqq9P5pb1LoWtSyDk=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
