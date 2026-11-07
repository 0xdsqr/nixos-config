{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.319";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-H1NYfpLe6OCJ+jSRiKTNpk+jSs5uewyi7ieN2qPMLr0=";
    darwin-x64 = "sha256-r28fVRCumNVqFVv48AeqnVtE78zJwQyOEO81A56VqUA=";
    linux-arm64 = "sha256-p+aH/RywVNZRx1iCI943hsmdTGgjZePDrh5Zzn86WR8=";
    linux-x64 = "sha256-2rr+yCyhMZ+kPYvjahD8YbHRGCHLmK1d8ErZXhmbju0=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
