{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.207";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-E5egYsaIlnUFXjMU3ZVjdqxRJip3NK2egZwml11xVHo=";
    darwin-x64 = "sha256-ikNV0lGmDJDYzwjzL9siqBV909CFVC+V0NoEdfmixXw=";
    linux-arm64 = "sha256-i8FKKEBlODRg83mB1yS496p8qTyYSdL+Nn4I8DOD9FQ=";
    linux-x64 = "sha256-hefpiKOS2Fn5CALKIfsm6J08mrUn9e0LCN85VeNNXIM=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
