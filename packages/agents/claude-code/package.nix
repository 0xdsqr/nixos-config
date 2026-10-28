{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.312";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-a17GkRleVRsCxB3599cj9Oph6qA8LfkKzv43NvGutiA=";
    darwin-x64 = "sha256-lTR3DhYs/W45MB2at3Wv/OIU3wMqaEhAhb26uWan+M8=";
    linux-arm64 = "sha256-3EryiRdFXgCdJnBLgqQ4NToGFJ6CW2zfeCkIstKGYfU=";
    linux-x64 = "sha256-T0F4zkHYPiM0Hr+67NvPjqa/e66gaQAlq+Se7sOl0B0=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
