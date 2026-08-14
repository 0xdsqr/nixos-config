{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.232";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-eznBWI35GdAB3qP/1WUa22gvJFG1oOGNQtQjMpa1PMc=";
    darwin-x64 = "sha256-qj1gbXvw6pc5ptDeEYEOcqZi56TlBh1n7n+LxHyIkPk=";
    linux-arm64 = "sha256-IHl+vGRN/EemmGXEbVz3Asfb7dSNQmgGO4go69VbOdA=";
    linux-x64 = "sha256-YdI/h0kTaQfVhtWxGDHqilI01MHepApeVcM7UuIExtE=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
