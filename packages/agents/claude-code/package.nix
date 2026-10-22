{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.308";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-ypI8hqyEswV0qCMxoFtuBmwnR3qSbOr/5GqEWjPk3Tc=";
    darwin-x64 = "sha256-mgvBQPX7BuY2ZiTXcDce8pDmcx0ehMTe9dr035RtG1k=";
    linux-arm64 = "sha256-/dIubLtzTVgPVmTEjfQpTu7IUCGP8H8Yb5rzBCY5buE=";
    linux-x64 = "sha256-NWcz8YX6mI5r86qaVVJp/dFnmCouKoDTyKeAN7uSrVg=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
