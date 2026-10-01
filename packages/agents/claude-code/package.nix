{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.286";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-deMBbp0lcHZ7COQ6dGfUgXpPFJIywWnKKV8slf7yFDM=";
    darwin-x64 = "sha256-U+apNuiVGdaVIw+cyXlDmRKGtydmZ0+6Eb7oRfCnwEc=";
    linux-arm64 = "sha256-ApL6Iqwv1D4Wvp0OUR3dg0coDW4Ousp0TvWyfgXY0Pg=";
    linux-x64 = "sha256-/lA/ZcYonVnCPlshrkTwNYP5l90zosv8datPlvuPxz8=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
