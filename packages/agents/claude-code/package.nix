{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.247";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-UIa5tk2LuELh9ZnN03Z6sIxrImbkYvzFaGrksBnMqPc=";
    darwin-x64 = "sha256-Fi5l17+HNdvNx1sBItuxJtVwSgDmgrvfxBN0kYiiDP0=";
    linux-arm64 = "sha256-pou2M/heSg5zRllS6mJM8YmSw/pNthX+65Qv+tV9CCo=";
    linux-x64 = "sha256-X7Mhv0F//FzU4/NufJx+Apv0eqo21WIduXn8xebqvhU=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
