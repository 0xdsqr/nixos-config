{ claude-code, lib }:
let
  version = "2.1.325";

  checksums = {
    darwin-arm64 = "5117df01bb8150ced024d8944a9706034e0c9bf6e28ee527b8d7735397aca6db";
    darwin-x64 = "d92be13773f84a1cb0a378dcb0aa67dcd2c8262645f25bfa0dd7b1af21972cf2";
    linux-arm64 = "9e0304bfa6890a8badad29f40061f90a2a6fd704d9d47b44efc10ab74184a0ee";
    linux-x64 = "00b1b977bcc3f32eb69129f0ac3277aafb1aecbfb87c17c0af53806832ed436a";
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
