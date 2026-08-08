{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.226";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-AToc8X31/x3MGJ1db9P91fCX3cPNQaqZkumYBVdP674=";
    darwin-x64 = "sha256-dzsJWHbxPduDNr+uICpXxi41ixiCdG8dVeNoBgGjLFk=";
    linux-arm64 = "sha256-/rcV7gZtAqQAydg5QVkvEcjo+mYowePBQmK8Up+VBJg=";
    linux-x64 = "sha256-TpvsEXfOlpDovZiLcQrCQQXnDaQo3QlMWty754alVVU=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
