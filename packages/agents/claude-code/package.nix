{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.287";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-bquDM/4hIVUxANj0C/raOEo+mJuU+Ufhi6Znem/LQeo=";
    darwin-x64 = "sha256-8YYyE+T1WqrcLm7mF/k0raKZMOXeTF5fj540oNWU/dc=";
    linux-arm64 = "sha256-5Nr3k9HnT7DZh03QnphpC7/XvlFfeKh/0FueK0uzOwM=";
    linux-x64 = "sha256-OSBImlEJz/V4aho5LCUndAj/Irx5bV7bnBamDloXGPA=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
