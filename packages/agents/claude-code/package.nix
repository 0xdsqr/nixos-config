{ claude-code, lib }:
let
  version = "2.1.328";

  checksums = {
    darwin-arm64 = "5c1e357bada5a66373e0705cb0e1213d3e49d086de0dcc11892e3063bc9da5dc";
    darwin-x64 = "6e2c9fb67e81932a0ec2255dbdc3e975035ba3dc2bc091de44186330662df54c";
    linux-arm64 = "c92f528d76713f97e5c7f443fc2459670a833182cb4314575ec939dadb4c77b5";
    linux-x64 = "10f24c9cfcbf3c586e6d281815dce9b561eb8acc6b8c0f26b8f0af5e56fa7605";
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
