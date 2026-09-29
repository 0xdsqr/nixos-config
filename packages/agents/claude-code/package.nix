{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.284";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-UKFML1D1Zmg4D92kkBZ/HTYw1cwY+4rtMHPCx+pzFP4=";
    darwin-x64 = "sha256-eUQbhok1oR7QYwsu5ZMn7an2qTu41HC9ZjPAPfdtITU=";
    linux-arm64 = "sha256-PdD5bXraRjFS0gMAGG9s/Gq5S1fiGPSeOshttCrGlaY=";
    linux-x64 = "sha256-XNkKq9g/ihUTbDWqN7sdkrNImTVzMWZD3D/k4Er7+I8=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
