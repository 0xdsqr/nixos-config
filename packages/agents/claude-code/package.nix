{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.296";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-ybU0Fje+y9Qj3f/FslSvtkVoKjhoy3CLvGzA57tBmTc=";
    darwin-x64 = "sha256-pr9PML4kEFOpI/OCCtI8WZHS9awpNbOo3WTaIY2cxgM=";
    linux-arm64 = "sha256-8fbpbg2DQrnb9B1+iCVTl6alLOPYc2rWpMa1nJti/vo=";
    linux-x64 = "sha256-JJcuO8hZ+rK0btTB5R99YTDwbTvVUIEaEUZA3jNw0N4=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
