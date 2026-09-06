{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.263";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-710pCcivSfMattVIfpAxZ3e8L6wXCt/oFgcWyqiq9Pk=";
    darwin-x64 = "sha256-qUqLIp+oXDoxbGtKNeCqIr7BqrvT0UIoJs4dEN3Ih1E=";
    linux-arm64 = "sha256-fSXXyK5sbgCcx9rk6Bf2dBef0x+3dhvNVv7kwpArTAM=";
    linux-x64 = "sha256-JtAgNR6BEvQAZ5Dzz85DtMnfDBux0OVCNk1kFRuB1bo=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
