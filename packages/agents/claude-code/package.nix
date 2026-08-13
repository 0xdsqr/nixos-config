{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.229";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-1zLwugpTnFjC/8rvBu0DtOUjcm8Mtswns6W3564KeiE=";
    darwin-x64 = "sha256-HLYhg+n4nqIetJULhIlvpxARgsffy76S56KT8LILpUE=";
    linux-arm64 = "sha256-ulMTCsvaPdsAs91WQfEXM4Z/XYN6JYt+bM70knzBpQk=";
    linux-x64 = "sha256-IAM4E5o98Eqa0iIzg30ftT+23/ohzYLkdVm/qhFazBs=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
