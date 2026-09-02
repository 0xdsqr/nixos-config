{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.258";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-tjE2GUFgeRwnz6ewQDBg2F6wdSmRYl/ejAn5rKyxfHg=";
    darwin-x64 = "sha256-yFfbXNcShlYjvWHoBs8/fo4nnJ5cfAr17KBspnF/x/s=";
    linux-arm64 = "sha256-Q9xJCvVSYu3LPpscsxXeIswJzLCL1SpMObxeq6pjEA8=";
    linux-x64 = "sha256-cE8TNKxl0+ieHGwddmMpOteGphZq/bcbUHUzffYw+XY=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
