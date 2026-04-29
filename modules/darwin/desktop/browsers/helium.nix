{ lib, ... }:
let
  inherit (lib.generators) toPlist;
  inherit (lib.lists) singleton;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption;

  ublockId = "cjpalhdlnbpafiamejdnhcphjbkeiagm";

  heliumPolicy = {
    ExtensionInstallForcelist = singleton "${ublockId};https://services.helium.imput.net/ext";
    ExtensionInstallAllowlist = singleton ublockId;
    ExtensionInstallSources = singleton "https://services.helium.imput.net/*";
  };

  managedPolicyPlist = toPlist { escape = true; } heliumPolicy;
in
{
  flake.darwinModules.helium =
    { config, ... }:
    let
      cfg = config.dsqr.darwin.desktop.browsers.helium;
    in
    {
      options.dsqr.darwin.desktop.browsers.helium.enable = mkEnableOption "Helium browser managed policy" // {
        default = true;
      };

      config = mkIf cfg.enable {
        system.activationScripts.script.text = mkAfter /* bash */ ''
          ${config.system.activationScripts.helium.text}
        '';

        system.activationScripts.helium.text = /* bash */ ''
          echo "setting up helium policy..."
          /usr/bin/install -d -m 755 "/Library/Managed Preferences"
          /bin/cat > "/Library/Managed Preferences/net.imput.helium.plist" <<'PLIST_EOF'
          ${managedPolicyPlist}
          PLIST_EOF
          /usr/sbin/chown root:wheel "/Library/Managed Preferences/net.imput.helium.plist"
          /bin/chmod 0644 "/Library/Managed Preferences/net.imput.helium.plist"
        '';
      };
    };
}
