{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.311";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-hdjAhwf8/R54/6AgTu+8bsnk/iLzdfsnZ++F2VftMWE=";
    darwin-x64 = "sha256-004cuCAVsFBHGpdXSqbqb2mOzzqXphyYCWH0Otn4OPU=";
    linux-arm64 = "sha256-LiSWyagGXfk6yw/KLTQfWaa4d3ZJsuAlq4ybzV7vYfM=";
    linux-x64 = "sha256-htwfzGlJgVnq8V9EZhPoRwEPkDa/u9/9TEk1C+hImto=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
