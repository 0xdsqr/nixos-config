{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.233";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-vEZrbN5j7a/Hc/RxofuYeH+rsx9SJAyGFs5+H1h7IS0=";
    darwin-x64 = "sha256-izrhjfQRCYzlVwXEuxUenJfjTfVf43nHtrMSKmnw6nQ=";
    linux-arm64 = "sha256-Qt8YQfdOmyrBPywaKoIO9rmsWy77hka7JcmpK4vWkZQ=";
    linux-x64 = "sha256-VdKBCW9X1BHrvdlNv16f86zLfAVxPjc0jCwR1Lg7+dk=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
