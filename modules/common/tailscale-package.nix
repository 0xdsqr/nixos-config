{ lib, ... }:
let
  version = "1.102.2";
in
{
  flake.overlays.tailscale-security = final: prev: {
    tailscale =
      if lib.versionOlder prev.tailscale.version version then
        prev.tailscale.overrideAttrs {
          inherit version;

          src = final.fetchFromGitHub {
            owner = "tailscale";
            repo = "tailscale";
            tag = "v${version}";
            hash = "sha256-vqNShvER4jT+8WJCcaSVboXPEP6S3QacmkC39tJkR4g=";
          };

          vendorHash = "sha256-amKkUPszyhG4N5ZtrB01swBACYq76raSS+SQRneLmwc=";

          ldflags = [
            "-w"
            "-s"
            "-X tailscale.com/version.longStamp=${version}"
            "-X tailscale.com/version.shortStamp=${version}"
          ];
        }
      else
        prev.tailscale;
  };
}
