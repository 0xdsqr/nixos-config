{ lib, ... }:
let
  inherit (lib.generators) toPlist;
  inherit (lib.lists) singleton;
  inherit (lib.modules) mkAfter;

  ublockId = "cjpalhdlnbpafiamejdnhcphjbkeiagm";

  heliumPolicy = {
    ExtensionInstallForcelist = [ "${ublockId};https://services.helium.imput.net/ext" ];
    ExtensionInstallAllowlist = [ ublockId ];
    ExtensionInstallSources = singleton "https://services.helium.imput.net/*";
  };

  managedPolicyPlist = toPlist { escape = true; } heliumPolicy;
in
{
  flake.darwinModules.google-chrome =
    { pkgs, ... }:
    {
      allowedUnfreePackageNames = [ "google-chrome" ];
      environment.systemPackages = singleton pkgs.google-chrome;
    };

  flake.darwinModules.helium =
    { config, ... }:
    {
      system.activationScripts.script.text = mkAfter ''
        ${config.system.activationScripts.helium.text}
      '';
      system.activationScripts.helium.text = ''
        echo "setting up helium policy..."
        /usr/bin/install -d -m 755 "/Library/Managed Preferences"
        /bin/cat > "/Library/Managed Preferences/net.imput.helium.plist" <<'PLIST_EOF'
        ${managedPolicyPlist}
        PLIST_EOF
        /usr/sbin/chown root:wheel "/Library/Managed Preferences/net.imput.helium.plist"
        /bin/chmod 0644 "/Library/Managed Preferences/net.imput.helium.plist"
      '';
    };
}
