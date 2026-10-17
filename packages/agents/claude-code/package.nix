{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.302";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-UmLOnehiQ/7Q0h7cObJxVV1WeA0BEuKxlEOf4cZmLTc=";
    darwin-x64 = "sha256-uakTEU9Chw7I44hIyIyFXXP3MYeHHsLhrQW75UAp2aw=";
    linux-arm64 = "sha256-K9T05e1csJlVtJAJj3RTIctUkefqjHUroeO7AQza2xA=";
    linux-x64 = "sha256-YNfrfxL7sopSUz/ovliECXQDViqgLcc5kaAhxwZ+KaU=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
