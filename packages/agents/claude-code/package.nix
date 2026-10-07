{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.292";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-l6AeW8dKGZ5nGJQ10DMeo6JOrC4H20t22RSMWwOGE48=";
    darwin-x64 = "sha256-qXOaIVcoznJDWIX+2xnRMX7hzOxh4kb7+zrK8BaJxHM=";
    linux-arm64 = "sha256-JMqp5v8TvyJwSaJibxyBb8iVAjBQ8Ow7EtvxTYlzZ+A=";
    linux-x64 = "sha256-qWfnsdi05H7kIdVDMCeIA0eVKwwIV6v4gOLJQqTsk7M=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
