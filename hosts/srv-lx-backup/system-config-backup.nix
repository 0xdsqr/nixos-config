{ pkgs, ... }:
let
  repository = "/var/lib/backup/system-config/proxmox";
in
{
  programs.ssh.knownHosts.proxmox = {
    hostNames = [ "10.10.10.109" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUG4TX9b5LNthwzHg7CYSWibGNjh3bH2hOo+OSrVoRD";
  };

  systemd.services.proxmox-config-backup = {
    description = "Back up Proxmox configuration";
    after = [
      "network-online.target"
      "var-lib-backup.mount"
    ];
    wants = [ "network-online.target" ];
    requires = [ "var-lib-backup.mount" ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    path = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.openssh
    ];
    script = ''
      install -d -o root -g root -m 0700 ${repository}

      timestamp="$(date --utc +%Y%m%dT%H%M%SZ)"
      temporary_file="${repository}/.''${timestamp}.tar.gz.tmp"
      final_file="${repository}/.''${timestamp}.tar.gz"

      ssh \
        -i /etc/ssh/ssh_host_ed25519_key \
        -o BatchMode=yes \
        -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=yes \
        root@10.10.10.109 \
        > "$temporary_file"

      test -s "$temporary_file"
      mv "$temporary_file" "$final_file"
      find ${repository} -type f -name '*.tar.gz' -mtime +31 -delete
    '';
  };

  systemd.timers.proxmox-config-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:15:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
