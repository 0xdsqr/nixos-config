{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.224";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-OR350qsE5M8yGZM1cgrHcVpYLpHq7P1NIZihb1fqWbM=";
    darwin-x64 = "sha256-euF6dopycMe9bFSEWHw8ZQ3/QltL7usDrdwfKkp9cCo=";
    linux-arm64 = "sha256-PlCDbiJ4aHRic2U+D4EVz1/JyzSggYR8YEDIHYCBLDM=";
    linux-x64 = "sha256-orWt19xLzY6qAp9Oi9rE33dptAc2mNt5idIGuvlBnC0=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
