{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.216";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-0BtJIQ1y7L4neiZl0QS6zM3fLSIYW+mURtKSng7fxI0=";
    darwin-x64 = "sha256-4XzcUUN716gM4CRNJQRfVo1nshLupP+BuD7pD4Zm5C8=";
    linux-arm64 = "sha256-njpq7MUWT2B+EYOuogksfXcF0UblBKYgffKRd2mWqOo=";
    linux-x64 = "sha256-dN7KRSILgIDsdasJm9WlmA5BorWHmEagCPsRXUNt4IU=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
