{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.222";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-xmpsxvougUW7Gm53gx8sr0uDaQ/wRlBQDfpuLAXKmXw=";
    darwin-x64 = "sha256-Nr/GSColcw27HO5yWJ5SLGbEWk3J6/3Yp2qBE7AbYYg=";
    linux-arm64 = "sha256-oEvgqNf+AllXGrdBHVHYVljXGkomzmK2DJCCkDcuYBY=";
    linux-x64 = "sha256-EMqujyK5FcJr//DgE6TUVgjE8a4odYNiZWkVb0R3MOU=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
