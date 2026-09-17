{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.274";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-NQmRP50VdjFsiEW4iDf4/Tu7zyZiWDOsgs+2uJhdqUo=";
    darwin-x64 = "sha256-sY6MnXZm2Jh6F0rGXgAZ9Lpr76c9L3XAXL6S5Qk0Mes=";
    linux-arm64 = "sha256-LbkE2uoXrd/53lV7ompyWRaIiqe1RuLF3ZicINnUmrM=";
    linux-x64 = "sha256-FeLQUUj4AbV3QDL6rYfmJOzRcumQMoi9pEi4kutY+gc=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
