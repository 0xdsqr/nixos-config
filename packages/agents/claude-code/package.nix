{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.289";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-A9ZnReO7aexyfWYCNpbzggvAoAqKW6cl62cG0MZ8vmk=";
    darwin-x64 = "sha256-NYqg4xZmxIsjQK2fpAA0NhBQhsoS4ezUxSZtGFmML38=";
    linux-arm64 = "sha256-0QDV5B3L7iIMgNOjCZKS5LWlCLV8r9GBhW7+3yn4Tyg=";
    linux-x64 = "sha256-oYa5nkqciDZs1J3y99rVbGH8MG7wFAsZ7mS3xCqNE0g=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
