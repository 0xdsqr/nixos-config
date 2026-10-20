{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.304";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-uaxTdIOfFKvz8fRWEGN8MytdruXODRY0cmzvh6q3jmo=";
    darwin-x64 = "sha256-8q5Am0axvcHex6+hLGoJT/ZOfUyicsoJ9p3QCAyEZwM=";
    linux-arm64 = "sha256-xIcRdSZQmrbS7mAT4U8YH69o1tav5rsNSytKn+yl7LM=";
    linux-x64 = "sha256-6g8TV4RjFhmnpAnQcyLs7JZPnMT9N3UI7Ruj8UHyeRI=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
