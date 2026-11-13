{ claude-code, lib }:
let
  version = "2.1.323";

  checksums = {
    darwin-arm64 = "20788f38f520395da5dc315ba6ef2f86c6a0850d9104e6b870cd980697e81055";
    darwin-x64 = "429ba46778e710d5aa2ad1f393bbaa50ed1caec06f2857bf7f4aeb37a5d04590";
    linux-arm64 = "fe84a70e49198b4489aeadbe08cdbfb6a01abf2ca0d8dfe861d5f933e4e1516b";
    linux-x64 = "d5f85ac4e9b7ca95e6bbeeeaf05af7c20ff62ddd2a0f49b1f4a0699c30ab0686";
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
