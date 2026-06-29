{ self, ... }:
let
  homeRootCAFile = self + /certs/dsqr-home-root-ca.pem;
in
{
  flake.commonModules.certificates =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) path;

      cfg = config.dsqr.security.certificates.homeRootCA;
    in
    {
      options.dsqr.security.certificates.homeRootCA = {
        enable = mkEnableOption "DSQR Home Root CA trust";

        certificateFile = mkOption {
          type = path;
          default = homeRootCAFile;
          description = "Public DSQR Home Root CA certificate to add to host trust bundles.";
        };
      };

      config = mkIf cfg.enable { security.pki.certificateFiles = [ cfg.certificateFile ]; };
    };

  flake.darwinModules."system-keychain-certificates" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.security.certificates.homeRootCA;
      keychainCfg = config.dsqr.darwin.security.certificates.homeRootCA.systemKeychain;
    in
    {
      options.dsqr.darwin.security.certificates.homeRootCA.systemKeychain.enable =
        mkEnableOption "installing the DSQR Home Root CA into the macOS System keychain"
        // {
          default = false;
        };

      config = mkIf (cfg.enable && keychainCfg.enable) {
        system.activationScripts.script.text = lib.mkAfter /* bash */ ''
          ${config.system.activationScripts.dsqrHomeRootCA.text}
        '';

        system.activationScripts.dsqrHomeRootCA.text = /* bash */ ''
          echo "trusting DSQR Home Root CA in the macOS System keychain..."

          cert="${cfg.certificateFile}"
          keychain="/Library/Keychains/System.keychain"
          fingerprint=$(/usr/bin/openssl x509 -in "$cert" -noout -fingerprint -sha256 | /usr/bin/sed 's/^.*=//; s/://g' | /usr/bin/tr '[:lower:]' '[:upper:]')

          if /usr/bin/security find-certificate -a -Z "$keychain" | /usr/bin/grep -q "$fingerprint"; then
            /usr/bin/security delete-certificate -Z "$fingerprint" "$keychain" >/dev/null 2>&1 || true
          fi

          /usr/bin/security add-trusted-cert -d -r trustRoot -k "$keychain" "$cert"
        '';
      };
    };
}
