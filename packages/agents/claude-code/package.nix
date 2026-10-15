{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.300";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-R1UXyqYR4zGKLymPoHEofsmJVVON94xY9wnswB5a4tM=";
    darwin-x64 = "sha256-WCT8NoY+cLvQcEkbuTWeIX0/F7OMRWl8CFsxo6ZzVrM=";
    linux-arm64 = "sha256-riKVri2hVpNr9YMasBlxzpJNDJoK8XTijZb/+o1foKY=";
    linux-x64 = "sha256-Z03roLupruR59FA8Q4tJMDtv3TBLmkcbFJd6rsUhVFM=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
