{
  flake.nixosModules.vault-certificates =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets)
        mapAttrs
        mapAttrs'
        mapAttrsToList
        nameValuePair
        optionalAttrs
        ;
      inherit (lib.lists) optional;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkOption;
      inherit (lib.types)
        attrsOf
        float
        nullOr
        package
        path
        str
        submodule
        ;

      cfg = config.dsqr.nixos.vaultCertificates;

      secretName = name: "vaultCertificate-${name}SecretId";
      roleIdFile = name: certificate: pkgs.writeText "vault-certificate-${name}-role-id" certificate.roleId;

      templateContents = certificate: /* go-template */ ''
        {{- with pkiCert "${certificate.issuePath}" "common_name=${certificate.commonName}" "ttl=${certificate.ttl}" -}}
        {{ .Data.Key | writeToFile "${certificate.privateKeyFile}" "${certificate.owner}" "${certificate.group}" "${certificate.privateKeyMode}" }}
        {{ .Data.Cert }}{{ .Data.CA }}
        {{- end -}}
      '';
    in
    {
      options.dsqr.nixos.vaultCertificates = mkOption {
        type = attrsOf (
          submodule (
            { name, ... }: {
              options = {
                package = mkOption {
                  type = package;
                  default = pkgs.vault-bin;
                  defaultText = "pkgs.vault-bin";
                  description = "Vault package used by the agent.";
                };

                vaultAddress = mkOption {
                  type = str;
                  default = "https://vault.service.home.arpa:8200";
                  description = "Vault server used for certificate issuance.";
                };

                caCertificateFile = mkOption {
                  type = str;
                  default = "/etc/ssl/certs/ca-certificates.crt";
                  description = "CA bundle used to verify the Vault server.";
                };

                roleId = mkOption {
                  type = str;
                  description = "Non-secret Vault AppRole role ID.";
                };

                secretIdAgeFile = mkOption {
                  type = path;
                  description = "Encrypted age file containing only the Vault AppRole secret ID.";
                };

                issuePath = mkOption {
                  type = str;
                  description = "Vault PKI certificate issue path.";
                  example = "pki_int/issue/postgresql-listener";
                };

                commonName = mkOption {
                  type = str;
                  description = "DNS name requested for the certificate.";
                };

                ttl = mkOption {
                  type = str;
                  default = "720h";
                  description = "Requested certificate lifetime.";
                };

                renewalThreshold = mkOption {
                  type = float;
                  default = 0.75;
                  description = "Fraction of certificate lifetime after which Vault Agent rotates it.";
                };

                directory = mkOption {
                  type = str;
                  default = "/var/lib/vault-certificates/${name}";
                  description = "Directory containing the rendered certificate and private key.";
                };

                certificateFile = mkOption {
                  type = str;
                  default = "/var/lib/vault-certificates/${name}/certificate.pem";
                  description = "Rendered leaf certificate and issuing CA chain.";
                };

                privateKeyFile = mkOption {
                  type = str;
                  default = "/var/lib/vault-certificates/${name}/private-key.pem";
                  description = "Rendered certificate private key.";
                };

                owner = mkOption {
                  type = str;
                  default = "root";
                  description = "User that owns the rendered certificate material.";
                };

                group = mkOption {
                  type = str;
                  default = "root";
                  description = "Group that owns the rendered certificate material.";
                };

                certificateMode = mkOption {
                  type = str;
                  default = "0644";
                  description = "Mode applied to the rendered certificate.";
                };

                privateKeyMode = mkOption {
                  type = str;
                  default = "0600";
                  description = "Mode applied to the rendered private key.";
                };

                reloadUnit = mkOption {
                  type = nullOr str;
                  default = null;
                  description = "Systemd unit reloaded after certificate rotation.";
                };
              };
            }
          )
        );
        default = { };
        description = "Certificates issued and rotated by Vault Agent.";
      };

      config = mkIf (cfg != { }) {
        age.secrets = mapAttrs' (
          name: certificate:
          nameValuePair (secretName name) {
            file = certificate.secretIdAgeFile;
            owner = "root";
            group = "root";
            mode = "0400";
          }
        ) cfg;

        services.vault-agent.instances = mapAttrs (name: certificate: {
          inherit (certificate) package;
          user = "root";
          group = "root";
          settings = {
            vault = {
              address = certificate.vaultAddress;
              ca_cert = certificate.caCertificateFile;
            };

            auto_auth.method = [
              {
                type = "approle";
                config = {
                  role_id_file_path = roleIdFile name certificate;
                  secret_id_file_path = config.age.secrets.${secretName name}.path;
                  remove_secret_id_file_after_reading = false;
                };
              }
            ];

            template_config = {
              exit_on_retry_failure = false;
              lease_renewal_threshold = certificate.renewalThreshold;
            };

            template = [
              (
                {
                  contents = templateContents certificate;
                  destination = certificate.certificateFile;
                  user = certificate.owner;
                  inherit (certificate) group;
                  perms = certificate.certificateMode;
                  create_dest_dirs = true;
                  error_on_missing_key = true;
                }
                // optionalAttrs (certificate.reloadUnit != null) {
                  command = [
                    "${pkgs.systemd}/bin/systemctl"
                    "--no-block"
                    "try-reload-or-restart"
                    certificate.reloadUnit
                  ];
                  command_timeout = "30s";
                }
              )
            ];
          };
        }) cfg;

        systemd.tmpfiles.rules = mapAttrsToList (
          _: certificate: "d ${certificate.directory} 0750 ${certificate.owner} ${certificate.group} - -"
        ) cfg;

        systemd.services = mapAttrs' (
          name: certificate:
          nameValuePair "vault-agent-${name}" {
            before = optional (certificate.reloadUnit != null) certificate.reloadUnit;
            requiredBy = optional (certificate.reloadUnit != null) certificate.reloadUnit;
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];

            serviceConfig = {
              UMask = "0077";
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectHome = true;
              ProtectSystem = "strict";
              ReadWritePaths = [ certificate.directory ];
            };
          }
        ) cfg;
      };
    };
}
