{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.288";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-u+kwY/egh5oQIbKJHlyTVOWzuYQz4y7+Z1D3cQr+11A=";
    darwin-x64 = "sha256-lGrKsDpVtg4gFuMJZMSLlu9mc8tdpoQ4P0g12kEO7eA=";
    linux-arm64 = "sha256-NZq2oFj83pdB3/VJeaIS/RNM346M/C+N4CvDULniudU=";
    linux-x64 = "sha256-ApgGi2huf9uvlAKnpYe7f0nAsOCE3gn2kUWgcZIHZAw=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
