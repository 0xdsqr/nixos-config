{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.322";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-qdI3lJ24FqC3r9iKmo4d82s6WXow9aQdHAU56xgKNFA=";
    darwin-x64 = "sha256-tRPRURfL8bsFCV2rQZY/05T/QN4fqZ3MbX0QM78pLps=";
    linux-arm64 = "sha256-8iDKUOpPMiIEP/g8wiShJi4BlumJeswIce+pQjWwwf0=";
    linux-x64 = "sha256-v7NwOtU4AkIyhFm8Yq2kveiue6V8bh7q25wA4Ih0xHg=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
