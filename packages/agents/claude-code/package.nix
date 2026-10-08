{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.294";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-3vDRXmTdfYliH4jSghT4hbHDiw3daXYvuFk+NJFdbVM=";
    darwin-x64 = "sha256-tPikp6Q7U/8c1jnYO9Bw6K+HJdnLUavSV6nGEc5scnQ=";
    linux-arm64 = "sha256-5dLfGfMKbWO/ERiBIfftsndSSbVzUqaSaVCaSxSW52M=";
    linux-x64 = "sha256-JxIsp7Yk9TdUb77zW4DGY3DZdP8ljz2bEKxQu4dx8mI=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
