{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.281";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-qSKYH287VaJR75+duqBiGl+Zy8tcpn+KeXR2zPyD9iY=";
    darwin-x64 = "sha256-qTVcuw0pHOlI789hpu85dAFnL2T6Xl5nvKCS/tbNkIg=";
    linux-arm64 = "sha256-3SezZDik/tFnDNKbrS/aanO2KLbaVUQ+XC9kf+btMo8=";
    linux-x64 = "sha256-Vv49qIRYRl+yfX6Smd3bP+rVV1D7nC3nlfIzte6m3OE=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
