{ claude-code, lib }:
let
  version = "2.1.322";

  checksums = {
    darwin-arm64 = "a542c514a07d0ca09408df2b8608be6c524389f232327d196b26f5b41056b813";
    darwin-x64 = "d81496870c5f569b718137d2e94ec4a7d05ed3333e904444cf5d99735786689b";
    linux-arm64 = "2c6be1e9fca1dcb894e47e11672f4432f4cf8a879f5e530289ad30802100c5d7";
    linux-x64 = "9bb7558bd992ca457e6458bf1686572f7a3156b8331dd8443391dbfe590c1eed";
  };

  manifest = {
    inherit version;
    platforms = lib.mapAttrs (_: checksum: {
      binary = "claude.zst";
      inherit checksum;
    }) checksums;
  };
in
claude-code.override { inherit manifest; }
