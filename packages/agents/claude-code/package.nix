{ claude-code, lib }:
let
  version = "2.1.331";

  checksums = {
    darwin-arm64 = "f129303752e09665843a586b1076e273568d1e5acaa5b2a6e62c316bb1cf6e5a";
    darwin-x64 = "1be3d8e06d1225899f4b74875b67928e9b8617fc7cb1c4f243aea1318083c8d4";
    linux-arm64 = "ce1ce2361762fa1944996e1f9a9ffeaf58d8e7383466c05ce4752c6c32d0046c";
    linux-x64 = "1466fdce6621ff0b69ae75faf43a35c9d2ff6a19523c42aa66a6858f566fcf62";
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
