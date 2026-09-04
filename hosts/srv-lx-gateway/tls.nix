_:
let
  certificate = {
    directory = "/var/lib/caddy/vault-pki/home-arpa";
    certificateFile = "/var/lib/caddy/vault-pki/home-arpa/fullchain.pem";
    privateKeyFile = "/var/lib/caddy/vault-pki/home-arpa/key.pem";
  };
in
{
  dsqr.nixos.caddy.certificate = {
    certFile = certificate.certificateFile;
    keyFile = certificate.privateKeyFile;
  };

  dsqr.nixos.vaultCertificates.caddy = {
    roleId = "eeea57d7-d565-4915-ca88-1c9a4038958c";
    secretIdAgeFile = ./caddy-pki.secret-id.age;
    issuePath = "pki_int/issue/gateway-caddy-home-arpa";
    commonName = "argocd.hub-a.home.arpa";
    altNames = [
      "argocd.indigo.home.arpa"
      "exo.home.arpa"
      "exo.service.home.arpa"
      "grafana.home.arpa"
      "prometheus.home.arpa"
      "rustfs.home.arpa"
      "temporal.home.arpa"
      "vault.home.arpa"
    ];
    inherit (certificate) directory certificateFile privateKeyFile;
    owner = "caddy";
    group = "caddy";
    privateKeyMode = "0640";
    reloadUnit = "caddy.service";
  };
}
