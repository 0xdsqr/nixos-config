{ claude-code, lib }:
let
  version = "2.1.329";

  checksums = {
    darwin-arm64 = "702e5ce4475e0446e7a7a1eef148f251f5e5e47b0902b6ae2e7b00f3d426f2a2";
    darwin-x64 = "847bd2085b9f6154e76575731a6847a57181779a0240357bb44eb0f85bb33f2a";
    linux-arm64 = "d5ffa30ef2d305feb76882125a7d2ed4524baf08843ebd21f4bff0409b2c62e9";
    linux-x64 = "e5e52a50cfab8a3573a4896846f499488d822b34e89a4994d8bc990aaf2846c4";
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
