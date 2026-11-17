{ claude-code, lib }:
let
  version = "2.1.326";

  checksums = {
    darwin-arm64 = "54df908478d26bca61942d6745b5e4c6a4f2af1d30f95566df2fe580d987a94c";
    darwin-x64 = "3c36ff5545e026161054cac99a061e7562327506d47838928391fdc8e0129b7e";
    linux-arm64 = "d5ca836da289593d5ebfc6bac21fa7954ad66f1eaf22f9860916ec0608d1ed2e";
    linux-x64 = "8a6e8f4fdc137f93359285d0677640dcd73e67a35ffabeab8c042d433d685abd";
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
