{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.241";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-FJXrfELTtEUfXxzTi21JjSKko4yAK8K+XBzxeV5kgg0=";
    darwin-x64 = "sha256-zwG4ys5mSF71tHbxTZb2mvYRlKOMPfhBKoDrjxMWwQ0=";
    linux-arm64 = "sha256-LbDLiT6+2O+K7kZlbaRbxoAfolhik9rmSr+jreiUov4=";
    linux-x64 = "sha256-B3G9hmz/grdlgfwEmfZSnho2hFB48UT4yB3Ms7xwN7g=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
