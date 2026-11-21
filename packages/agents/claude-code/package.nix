{ claude-code, lib }:
let
  version = "2.1.330";

  checksums = {
    darwin-arm64 = "c909e975f01193126bf28da4fa66825db4e9d10fd52b217106fdb3b9c7f6d247";
    darwin-x64 = "e41ce2e31839b08c232a4e42bc82a080f74ae0f203acf97cb5d144f959545ac6";
    linux-arm64 = "fd32a5b1552693c801e6f6cb3dc77e39c2438a873d00600558bae8bdc06b20bd";
    linux-x64 = "d53a3f9aab93c87bba0813d1101677677b457100824f5c3604fea9915ac5237a";
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
