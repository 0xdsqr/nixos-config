{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.269";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-yULhIouTy01SGDs9+8d/KCZPNaqUes2cCFPQKRZM9FA=";
    darwin-x64 = "sha256-WowC+f9I8ZF7OOhtg3EUuNXLv1NM5yvGqhBusX6zqQ8=";
    linux-arm64 = "sha256-TISjOtw0xg1N46zUPP58ZLqWZZHlFYfASGe41YkCG+Q=";
    linux-x64 = "sha256-JeRIg/VEGVaaPXOfOMu9rr6DsJiV2g80PhsANxCkd1s=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
