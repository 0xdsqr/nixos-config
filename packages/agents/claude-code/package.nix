{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.321";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-q8n+7sqAkdUbYjKR4ETPBSjC9rdODB1u9nHVLHP3zTw=";
    darwin-x64 = "sha256-9OBNhybuE0OZlnmtdF7KL20mPClB8TKx/cpCg+5tXwI=";
    linux-arm64 = "sha256-a+oGMwdGJ7p5Mo4AEV7QWIw6z5BqhGNhKyXbaW2/0/A=";
    linux-x64 = "sha256-QmwzgVymZFp3L3Ivv/ENvyy9sSSorqtzPBNl2/i79h8=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
