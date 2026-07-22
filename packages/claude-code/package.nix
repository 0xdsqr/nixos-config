{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.217";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-WEDHd/1HEV6conbhZVY8bhIefH4rTYZZjgAl+Mw33lY=";
    darwin-x64 = "sha256-g4em/UTt/UDX50xf3DJwoV9eaxtYx8b+5WDnDT0ZQ9o=";
    linux-arm64 = "sha256-QMU1B6xmnB1Dg2bBl2DCL1J0igblDg/A41PSy3NCVZc=";
    linux-x64 = "sha256-JjD8XcbbYbwD+GuV2vR3ZuXtW2GHP3u3z+p2TFrFqbo=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
