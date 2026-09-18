{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.276";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-neNk2xGkENU8u7D2sfGMZskAU+/JpjNwByhW0Q22Yyk=";
    darwin-x64 = "sha256-zwtK97zl2ZGld9EVDobUW3uD71fNsDhARMpUZh3tJMY=";
    linux-arm64 = "sha256-6aw9+VYINkVXijgq1k7DBEaGZuNiwzv979gDzW/1lrA=";
    linux-x64 = "sha256-ilbIoUvTyyRuK9t+YK7+D2Cb/3jIu8xeprGBfBEcYUU=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
