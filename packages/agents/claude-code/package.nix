{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.272";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-GV4k6OH5v0bx6u5y1DSjPhj59XlvKaY0igDRbF+K7nU=";
    darwin-x64 = "sha256-Y3e46V7L+Q/WuR5UOzwj4bI8nJaLKst61GDOVXPT5Bw=";
    linux-arm64 = "sha256-IUqQ790W7g6oETL/7M7ViNujlNF4zElPKFugS1KIyN4=";
    linux-x64 = "sha256-2BOWpmjrdvvdtJoqWEHxtdevlrTB9lAM7ZLyyYj1vNQ=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
