{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.197";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-jMDE0eTrHco7DMkqsC7jUF3nZOAj+MkBdhwWe3IEH7g=";
    darwin-x64 = "sha256-XopXzHqSN38HRPpMeRkc+T1LJsecuRmwekB1Ef7RviY=";
    linux-arm64 = "sha256-+0hHPEZ8J2Fax5mnVPTvC2jDY+RZbO+7WcOBXVGgzIo=";
    linux-x64 = "sha256-9U5py8ibLaYaQVcAr3/1KhR+hiUX1PGw7s92hEjPf4M=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
