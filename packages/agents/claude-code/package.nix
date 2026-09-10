{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.267";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-poHzAI8AUAKa7ryrOvUbtqVd3rYlo68xQaRBbUPNJVg=";
    darwin-x64 = "sha256-BxmIyy5aQ3jYVD144P9fjtHsxeETJxd0oFgu50+w73k=";
    linux-arm64 = "sha256-ImpOAJV0BEoYv1SV8SeAayob/L8ls8AWCHBfr+6V/vs=";
    linux-x64 = "sha256-A5nHk/9XHVlG75I9gLTzMNBaxLaEKmsHdUaPXTiUA8A=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
