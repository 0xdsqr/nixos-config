{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.228";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-Q0hLE1LO8DoING827wQ3dVsarWRquTE84YeFe3lLckc=";
    darwin-x64 = "sha256-eFLxrg77ZNRtd6V9iFLa3cSm/7WK7aYme9PzQorcCbM=";
    linux-arm64 = "sha256-JmQAYhlJe/cCGsQxVlGc1C7aZM6ypm9DTsq4Pngx+UI=";
    linux-x64 = "sha256-1TWYXmlBo+sAF5zNf1LOsMZiOgMFpRjrxOZRT4SpTJk=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
