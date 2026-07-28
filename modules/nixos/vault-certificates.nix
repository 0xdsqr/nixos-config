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
        attrNames
        mapAttrs
        mapAttrs'
        mapAttrsToList
        nameValuePair
        optionalAttrs
        ;
      inherit (lib.lists) optional;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkOption;
      inherit (lib.strings) concatStringsSep escapeShellArg optionalString;
      inherit (lib.types)
        attrsOf
        bool
        float
        listOf
        nullOr
        package
        path
        str
        submodule
        ;

      cfg = config.dsqr.nixos.vaultCertificates;

      cacheFile = certificate: "${certificate.directory}/agent-cache.pem";
      certificateMetricsDirectory = "/var/lib/alloy/textfile";
      certificateMetricsFile = "${certificateMetricsDirectory}/vault-certificates.prom";
      requestFingerprint =
        certificate:
        builtins.hashString "sha256" (
          builtins.toJSON {
            inherit (certificate)
              altNames
              commonName
              issuePath
              ttl
              vaultAddress
              ;
          }
        );
      requestFingerprintFile = certificate: "${certificate.directory}/request.sha256";
      invalidateStaleCacheScript =
        name: certificate:
        pkgs.writeShellScript "invalidate-stale-vault-certificate-cache-${name}" ''
          expected=${escapeShellArg (requestFingerprint certificate)}
          actual="$(${pkgs.coreutils}/bin/cat ${escapeShellArg (requestFingerprintFile certificate)} 2>/dev/null || true)"

          if [[ "$actual" != "$expected" ]]; then
            ${pkgs.coreutils}/bin/rm -f ${escapeShellArg (cacheFile certificate)}
          fi
        '';
      readinessScript =
        name: certificate:
        pkgs.writeShellScript "wait-for-vault-certificate-${name}" ''
          for _ in {1..60}; do
            if [[
              -s ${escapeShellArg (cacheFile certificate)}
              && -s ${escapeShellArg certificate.certificateFile}
              && -s ${escapeShellArg certificate.privateKeyFile}
            ]]; then
              exit 0
            fi

            sleep 1
          done

          echo "Timed out waiting for Vault Agent to render certificate ${escapeShellArg name}." >&2
          exit 1
        '';
      secretName = name: "vaultCertificate-${name}SecretId";
      roleIdFile = name: certificate: pkgs.writeText "vault-certificate-${name}-role-id" certificate.roleId;

      templateContents = certificate: /* go-template */ ''
        {{- with pkiCert "${certificate.issuePath}" "common_name=${certificate.commonName}"${
          optionalString (certificate.altNames != [ ]) " \"alt_names=${concatStringsSep "," certificate.altNames}\""
        } "ttl=${certificate.ttl}" -}}
        {{ .Cert }}{{ .CA }}{{ .Key }}
        {{ .Key | writeToFile "${certificate.privateKeyFile}" "${certificate.owner}" "${certificate.group}" "${certificate.privateKeyMode}" }}
        {{ .Cert | writeToFile "${certificate.certificateFile}" "${certificate.owner}" "${certificate.group}" "${certificate.certificateMode}" }}
        {{ .CA | writeToFile "${certificate.certificateFile}" "${certificate.owner}" "${certificate.group}" "${certificate.certificateMode}" "append" }}
        {{ "${requestFingerprint certificate}" | writeToFile "${requestFingerprintFile certificate}" "${certificate.owner}" "${certificate.group}" "${certificate.certificateMode}" }}
        {{- end -}}
      '';
      certificateMetricsScript = pkgs.writeShellApplication {
        name = "vault-certificate-metrics";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.openssl
        ];
        text = ''
          install -d -o root -g root -m 0755 ${certificateMetricsDirectory}
          temporary_file=${escapeShellArg certificateMetricsFile}.$$

          {
            printf '%s\n' \
              '# HELP dsqr_x509_certificate_expiry_timestamp_seconds Unix timestamp when a Vault Agent-managed certificate expires.' \
              '# TYPE dsqr_x509_certificate_expiry_timestamp_seconds gauge' \
              '# HELP dsqr_x509_certificate_valid Whether a Vault Agent-managed certificate is present and parseable.' \
              '# TYPE dsqr_x509_certificate_valid gauge'
            ${concatStringsSep "\n" (
              mapAttrsToList (name: certificate: ''
                expiry_timestamp=0
                valid=0
                if [[ -s ${escapeShellArg certificate.certificateFile} ]]; then
                  if expiry="$(
                    openssl x509 \
                      -in ${escapeShellArg certificate.certificateFile} \
                      -noout \
                      -enddate \
                      2>/dev/null \
                    | cut -d= -f2-
                  )"; then
                    if expiry_timestamp="$(date --date="$expiry" +%s 2>/dev/null)"; then
                      valid=1
                    else
                      expiry_timestamp=0
                    fi
                  fi
                fi
                printf 'dsqr_x509_certificate_expiry_timestamp_seconds{name="%s",common_name="%s"} %s\n' \
                  ${escapeShellArg name} \
                  ${escapeShellArg certificate.commonName} \
                  "$expiry_timestamp"
                printf 'dsqr_x509_certificate_valid{name="%s",common_name="%s"} %s\n' \
                  ${escapeShellArg name} \
                  ${escapeShellArg certificate.commonName} \
                  "$valid"
              '') cfg
            )}
          } > "$temporary_file"

          chmod 0644 "$temporary_file"
          mv "$temporary_file" ${escapeShellArg certificateMetricsFile}
        '';
      };
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

                altNames = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Additional DNS names requested for the certificate.";
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

                requireCertificateForUnitStart = mkOption {
                  type = bool;
                  default = true;
                  description = "Require the initial certificate render before starting the reload unit.";
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
                  destination = cacheFile certificate;
                  user = certificate.owner;
                  inherit (certificate) group;
                  perms = certificate.privateKeyMode;
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

        systemd = {
          services =
            mapAttrs' (
              name: certificate:
              nameValuePair "vault-agent-${name}" {
                before = optional (certificate.reloadUnit != null && certificate.requireCertificateForUnitStart) certificate.reloadUnit;
                requiredBy = optional (
                  certificate.reloadUnit != null && certificate.requireCertificateForUnitStart
                ) certificate.reloadUnit;
                requires = optional (
                  certificate.reloadUnit != null && !certificate.requireCertificateForUnitStart
                ) certificate.reloadUnit;
                after = [
                  "network-online.target"
                ]
                ++ optional (certificate.reloadUnit != null && !certificate.requireCertificateForUnitStart) certificate.reloadUnit;
                wants = [ "network-online.target" ];

                serviceConfig = {
                  ExecStartPre = invalidateStaleCacheScript name certificate;
                  ExecStartPost = readinessScript name certificate;
                  UMask = "0077";
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  ProtectHome = true;
                  ProtectSystem = "strict";
                  ReadWritePaths = [ certificate.directory ];
                };
              }
            ) cfg
            // {
              vault-certificate-metrics = {
                description = "Export Vault Agent-managed certificate expiry metrics";
                wantedBy = [ "multi-user.target" ];
                after = map (name: "vault-agent-${name}.service") (attrNames cfg);
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = lib.getExe certificateMetricsScript;
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  ProtectHome = true;
                  ProtectSystem = "strict";
                  ReadWritePaths = [ certificateMetricsDirectory ];
                };
              };
            };

          timers.vault-certificate-metrics = {
            description = "Refresh Vault Agent-managed certificate expiry metrics";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "1m";
              OnUnitActiveSec = "5m";
              RandomizedDelaySec = "30s";
              Persistent = true;
              Unit = "vault-certificate-metrics.service";
            };
          };
        };
      };
    };
}
