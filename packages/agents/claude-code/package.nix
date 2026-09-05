{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.261";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-Xv7K/yMbeYvjxm3vm+VBg2I7MouA6u8X+TxDmHAk6Co=";
    darwin-x64 = "sha256-LLwAKzJ3i9cKouZorakgxU2arNkbcdvVYZwByhSK5TM=";
    linux-arm64 = "sha256-e77VqbD8Lk7Ge600kNBsqRuG1rA31HUgt4mJUXV9G4o=";
    linux-x64 = "sha256-SuQN0XhOhXU+dC4J8mfSnsu4KJA2GtOBfSdWCGbTZKY=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
