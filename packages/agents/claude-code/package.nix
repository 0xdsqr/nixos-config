{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.266";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-VT0bnp5waLJ1wKeDx+E5/2UDCW8obmdMjJGTefsOymI=";
    darwin-x64 = "sha256-6AEBY75H4paB52iUaGUTBILoK7R7LF59DyF7rNJbUm0=";
    linux-arm64 = "sha256-bkTF08l++qHuNauN2HWpB2gXB+XMT2yg2j0TqRe7zts=";
    linux-x64 = "sha256-GYQnBemJOT/Ok2gE320qsDSGDiS4+IgDV5gdh//YP6w=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
