{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.223";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-/L4LjUdXDFATAt0a0xzCasKBDwIsRfolOTamlh3uMr8=";
    darwin-x64 = "sha256-NQ5ldCim00989x9nOMXrtqGVLMsS/BdH9kKX4GWxhG8=";
    linux-arm64 = "sha256-YOg9jbDolNDlRBPl59qiVtGA22YPUeE5pRthT8MM86w=";
    linux-x64 = "sha256-mCJkdPgC4wlNaobFreiIPBYgbQ/LXEALdAHIAAY+mdc=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
