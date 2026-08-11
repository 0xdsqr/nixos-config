{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.227";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-dDJRG6O+gY4B8j9u74Yw0hSothhFHhiMPH1hqYfu9sc=";
    darwin-x64 = "sha256-FEhPuaBIC2tjgjBoWn2aJIpTObOEoWLg3xJ+SkoHJJs=";
    linux-arm64 = "sha256-20czVTLLyrZ6SzqxbY8/d5dr+F1Tx9efgpZTiqIr/OY=";
    linux-x64 = "sha256-aDLcPxeXuJC3ERbl8tu/moP9PQSYwjW0sPnNDm5JmtY=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
