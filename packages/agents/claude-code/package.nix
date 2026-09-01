{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.257";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-ZFkNfZ2cGJ0z+z36WMVAjq8qEP5Va9hBVdle+qtGtg4=";
    darwin-x64 = "sha256-j5DAALHiZdzZKxLG2dE7tdNUxJXmuhXFbrFxACkj2As=";
    linux-arm64 = "sha256-IvfUjxcZOVLDwtC4vy8x2yzQj9X7CaN0+jIUlrcR0Bc=";
    linux-x64 = "sha256-mmS9qdhyKh+gW++aWWHQfgMxuZWX7ani9qcy86D/fwU=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
