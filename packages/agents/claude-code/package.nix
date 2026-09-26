{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.283";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-2MseXHloTMEqi/yBPjogc0BpIbYkV0SzAJvjq1ZR0h4=";
    darwin-x64 = "sha256-yJbSruEv9NlYYQM9lzDT0i3Bnk8yd5E00zme89+w53o=";
    linux-arm64 = "sha256-NG0pTwED1vwN4RrJU1ebXGLfqQaYpM/Ehrb5J8YV5pc=";
    linux-x64 = "sha256-GFlYPOMpIFlcYe+Gi+5S4bFZT3SG2yCZNeAfHl6ASuI=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
