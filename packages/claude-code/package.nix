{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.206";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-MZerpEQtvVs99CtvNebXvQO15Izhi3o8XG9fjCjgO38=";
    darwin-x64 = "sha256-seFjaRehLH1OH6VM0T9/dro3efuYgYBhC2ykgyWML0Y=";
    linux-arm64 = "sha256-y4zK9K5r61WHRyJ6NiAQxrMrT0pYaMOn6Wqply/G71g=";
    linux-x64 = "sha256-0TFJS+QH/1amL06ZqWumAQIALQHjtrFJTbFr70t/Bg8=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
