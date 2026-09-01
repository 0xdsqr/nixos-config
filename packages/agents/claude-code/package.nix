{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.252";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-tmHGoJT8wyZWv3wAccW0W/kAs01PChqz14/Vmuuiwsc=";
    darwin-x64 = "sha256-y9Q4kyKdOXugn1pdceObRYMrK4a2Gj6aMrt56bSQGHg=";
    linux-arm64 = "sha256-bAsy6qk2lUoPTUrSWV+EFq8ojZs8uvGePN2aldfIhT4=";
    linux-x64 = "sha256-pxWkUQXlk/yYCNA113eB+ISAuYl5danfQYN/DFkb1LM=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
