{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.282";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-/P2DcQOWXGTeNKa5uUNw13o0fqcYGXFaJ9Xw7wF3XqQ=";
    darwin-x64 = "sha256-XDSwC1wPOGK3YBEBXDNOkZBMRZOv6npUUeAHRq15NME=";
    linux-arm64 = "sha256-Z2T/w56f7UJaST/2HqKFBtG6g5ls6BpI0Rd9uzk0Gck=";
    linux-x64 = "sha256-Ov6FNcDMM/DiT3sl2rehcnuLWSGW+Elqi8MCuiFh7tM=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
