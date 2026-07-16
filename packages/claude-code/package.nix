{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.211";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-WnKKdhmLbsp/PHzb/0O6tEt3tIwhCPejEH2Il3M4Jik=";
    darwin-x64 = "sha256-MwSesUz0cCuZK37aQewHf8bnZTn3/QRubTJTh1cjXaQ=";
    linux-arm64 = "sha256-H/9+j5R8B7GdELH79xS35UfpU2JTubWCMNitvEYk+Gc=";
    linux-x64 = "sha256-gnLIpHSsnqG8NfGbn3x+fcTcTrbVrT5ISxkzWsckRrI=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
