{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.273";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-lT6YgNvLC3DzHB9Qjeaj/TiXU9ExaIVX/ZktqRhGk/s=";
    darwin-x64 = "sha256-IDDs+RHjAed4s8WkkGjWdROEyDDkjqFPEeth3SNiLO4=";
    linux-arm64 = "sha256-EDz6tNauiYtq9pIzb7Zi/8xgcHXMZAiJK9NQs/VJ6+4=";
    linux-x64 = "sha256-bHUuLMfBEMnfFfJtjRNNQ4xa6V29YQ78GjCL9/nF9sE=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
