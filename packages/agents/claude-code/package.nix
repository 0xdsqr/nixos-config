{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.238";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-HBlsRWNztXgYroffhK7O6Wy2WUSMDWpru0AaxXWEMbI=";
    darwin-x64 = "sha256-0QvHuxcgQ1+IMKo+50CF8JNI0rGioVK97iUbdw12zHM=";
    linux-arm64 = "sha256-KNc2EgprFMXq4a0UcOczcYGMnC+kHgs8cEAgeqLU7e4=";
    linux-x64 = "sha256-CTOyhs+U4bJQSzWsFlq3a4+CJzXVM3HFY5OYjCMEDVg=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
