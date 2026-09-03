{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.259";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-iEuqOP4aYkviXEqRVov1oItc9OfXrPKbd2DjUl2WSJg=";
    darwin-x64 = "sha256-r4dBz/DT+1xLiTx8s2E70hso+mHMpFRp1guOXhYeudg=";
    linux-arm64 = "sha256-xv8Dw4nM3q4PGencMkiO66YfvvR5b1Mdv7psAPRQQNA=";
    linux-x64 = "sha256-991irkFTeAGM0h3ZUOs7rBdKsIWDAwTTuLCYFGv9R7Y=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
