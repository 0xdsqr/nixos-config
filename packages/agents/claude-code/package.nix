{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.260";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-PCafZoAQKII+JKY87Z/dOYjLhs+F/M2fA/h+RjudPjw=";
    darwin-x64 = "sha256-LXkbG/8rw2QZ3gnh8iJsB2tAsHF+5DEIkok49iLqm3c=";
    linux-arm64 = "sha256-mBGvtflyJMLF09DuHowxYRfSmNXsPgldX/DB3Q6InKU=";
    linux-x64 = "sha256-ei/cdLaDbqPRg/ZluGnw7juuvJcTy+v/5YONpOp72C4=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
