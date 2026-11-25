{ claude-code, lib }:
let
  version = "2.1.332";

  checksums = {
    darwin-arm64 = "8a4cbdcb6279039c5584562a75154a818f622476c8e46de1f9ae1cbe40c12859";
    darwin-x64 = "b3b85859ab1151dae1c0c2e17f7f4e958a3ad73e00224b8655c1cb71abcc192a";
    linux-arm64 = "b76015ad1663566187a721e5641f6190722c0d2f95bfc35ff42ef4781fae0fa3";
    linux-x64 = "e9f53728e093fb9bea7e9c75094b6cfd7e6a82ee3791efbbf22238d6695f6220";
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
