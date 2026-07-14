{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.209";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-WdLef0nbL3XVwzu7Rqa48oitJNQLYeMGAqUCu33cOAw=";
    darwin-x64 = "sha256-TMP0S5BdRb0nptuTBuxt6Siup1hTcgUymFGuR48vosY=";
    linux-arm64 = "sha256-J4y2jvchfPzFyUnSVzu45ZqLEwX3Zon7qI63IrDZ4vA=";
    linux-x64 = "sha256-uIL0uLJ3cviXVA31DyQAAgb0OpQm6PfRm9BllZtp6d0=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
