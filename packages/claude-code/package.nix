{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.212";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-Cey6KrLfm27lsGleJvZd6mD7O2rz01Qu4J9GaDjR5XQ=";
    darwin-x64 = "sha256-doGgY0yJ+kR05TwMeU6ZKUSuvzQJp6K4fqn5sBlOo0E=";
    linux-arm64 = "sha256-ZuiGNKhXOgAnAuap3g2Ay5u3yQcvnm9EhneFOQV9/Tw=";
    linux-x64 = "sha256-BEqIzzpRgHdmF/09oSONy/kUHd7ESaOc99KvGseOaE4=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
