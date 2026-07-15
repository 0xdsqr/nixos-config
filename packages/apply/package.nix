{
  darwin-rebuild ? null,
  hostDefinitions ? { },
  lib,
  nh,
  nix,
  openssh,
  repoRoot ? ../..,
  rsync,
  writeShellApplication,
}:
let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) optional;
  inherit (lib.strings) concatStringsSep escapeShellArg;

  darwinRebuild = if darwin-rebuild == null then "darwin-rebuild" else "${darwin-rebuild}/bin/darwin-rebuild";

  hostCases = concatStringsSep "\n" (
    mapAttrsToList (
      hostName: hostMeta:
      let
        class = hostMeta.class or (throw "packages.apply: hostDefinitions.${hostName}.class is required");
      in
      /* bash */ ''
        ${escapeShellArg hostName})
          class=${escapeShellArg class}
          ;;
      ''
    ) hostDefinitions
  );
in
writeShellApplication {
  name = "apply";

  runtimeInputs = [
    nix
    nh
    openssh
    rsync
  ]
  ++ optional (darwin-rebuild != null) darwin-rebuild;

  text = /* bash */ ''
    set -euo pipefail

    host=""
    build_host=""
    target_host=""
    remote=0
    remote_root="nixos-config"
    remote_root_set=0
    identity_file="''${APPLY_SSH_IDENTITY:-}"
    ask_sudo_password=0
    dry_run=0
    positionals=()

    usage() {
      cat <<'EOF'
    usage: apply [options] <configuration>

      apply <configuration>
          Apply the selected configuration to the current machine.

      apply --remote <configuration>
          Sync this repository to the selected host and apply it there.

      apply --build-host <ssh-host> <configuration>
          Build a NixOS configuration on the SSH host, then activate its target.

      apply --target-host <ssh-host> <configuration>
          Override the SSH activation target.

    options:
      --remote
      --build-host <ssh-host>
      --target-host <ssh-host>
      --identity <path>
      --remote-root <relative-or-absolute-path>
      --ask-sudo-password
      --dry-run                Build and validate without activating.
      --help

    SSH destinations are passed to OpenSSH unchanged so Host aliases retain
    their configured User, IdentityFile, ProxyJump, and other connection settings.
    EOF
    }

    die() {
      printf 'apply: %s\n' "$*" >&2
      exit 2
    }

    require_value() {
      local option="$1"
      local count="$2"
      if (( count < 2 )); then
        die "$option requires a value"
      fi
    }

    while (( $# > 0 )); do
      case "$1" in
        --remote)
          remote=1
          shift
          ;;
        --build-host)
          require_value "$1" "$#"
          build_host="$2"
          shift 2
          ;;
        --target-host)
          require_value "$1" "$#"
          target_host="$2"
          shift 2
          ;;
        --identity)
          require_value "$1" "$#"
          identity_file="$2"
          shift 2
          ;;
        --remote-root)
          require_value "$1" "$#"
          remote_root="$2"
          remote_root_set=1
          shift 2
          ;;
        --ask-sudo-password)
          ask_sudo_password=1
          shift
          ;;
        --dry-run)
          dry_run=1
          shift
          ;;
        --help|-h)
          usage
          exit 0
          ;;
        --)
          shift
          positionals+=("$@")
          break
          ;;
        -*)
          die "unknown option: $1"
          ;;
        *)
          positionals+=("$1")
          shift
          ;;
      esac
    done

    if (( ''${#positionals[@]} != 1 )); then
      die "expected exactly one configuration; see --help"
    fi
    host="''${positionals[0]}"

    case "$host" in
    ${hostCases}
      *)
        die "unknown configuration: $host"
        ;;
    esac

    if (( remote == 1 )) && [[ -n "$build_host" || -n "$target_host" ]]; then
      die "--remote cannot be combined with --build-host or --target-host"
    fi
    if (( remote == 0 && remote_root_set == 1 )); then
      die "--remote-root requires --remote"
    fi
    ssh_args=(-o ServerAliveInterval=60 -o ServerAliveCountMax=20)
    nix_sshopts="''${NIX_SSHOPTS:-}"
    nix_sshopts="''${nix_sshopts:+$nix_sshopts }-o ServerAliveInterval=60 -o ServerAliveCountMax=20"
    sudo_args=()

    if [[ -n "$identity_file" ]]; then
      ssh_args+=(-i "$identity_file" -o IdentitiesOnly=yes)
      printf -v quoted_identity '%q' "$identity_file"
      nix_sshopts+=" -i $quoted_identity -o IdentitiesOnly=yes"
    fi
    if [[ -n "''${NIX_CONFIG:-}" ]]; then
      sudo_args+=(--preserve-env=NIX_CONFIG)
    fi

    if (( remote == 1 )); then
      tilde_prefix="$(printf '\176/')"
      if [[ "''${remote_root:0:2}" == "$tilde_prefix" ]]; then
        remote_root="''${remote_root#~/}"
      fi
      if [[ -z "$remote_root" || "$remote_root" == "/" || "$remote_root" == "." || "$remote_root" == ".." || "$remote_root" == "~" ]]; then
        die "refusing unsafe remote root: $remote_root"
      fi
      if [[ ! "$remote_root" =~ ^[A-Za-z0-9._/-]+$ ]]; then
        die "remote root may contain only letters, digits, '.', '_', '/', and '-'"
      fi

      remote_apply_args=()
      if (( ask_sudo_password == 1 )); then
        remote_apply_args+=(--ask-sudo-password)
      fi
      if (( dry_run == 1 )); then
        remote_apply_args+=(--dry-run)
      fi
      remote_apply_args+=("$host")
      printf -v remote_apply_command ' %q' "''${remote_apply_args[@]}"
      remote_cmd="cd -- $remote_root && exec nix --accept-flake-config run path:.#apply --$remote_apply_command"

      printf -v rsync_ssh '%q ' ${escapeShellArg "${openssh}/bin/ssh"} "''${ssh_args[@]}"
      ${rsync}/bin/rsync \
        --archive \
        --compress \
        --delete \
        --exclude .git \
        -e "$rsync_ssh" \
        ${escapeShellArg "${repoRoot}/"} \
        "$host:$remote_root/"

      activation_ssh_args=("''${ssh_args[@]}")
      if (( ask_sudo_password == 1 )); then
        activation_ssh_args+=(-t)
      fi
      exec ${openssh}/bin/ssh "''${activation_ssh_args[@]}" "$host" "$remote_cmd"
    fi

    if [[ -n "$build_host" || -n "$target_host" ]]; then
      if [[ "$class" == "darwin" ]]; then
        if [[ -n "$build_host" ]]; then
          die "--build-host is only supported for NixOS configurations"
        fi

        target="''${target_host:-$host}"
        system_config="$(
          ${nix}/bin/nix --accept-flake-config build \
            --no-link \
            --print-out-paths \
            ${escapeShellArg "${repoRoot}"}#darwinConfigurations."$host".system
        )"

        if (( dry_run == 1 )); then
          printf '%s\n' "$system_config"
          exit 0
        fi

        if (( ask_sudo_password == 1 )); then
          closure_file="$(mktemp "''${TMPDIR:-/tmp}/nixos-config-$host.closure.XXXXXX")"
          remote_closure="/tmp/nixos-config-$host-$(basename "$system_config").closure.nar"
          cleanup_closure() {
            rm -f "$closure_file"
          }
          trap cleanup_closure EXIT

          mapfile -t closure_paths < <(${nix}/bin/nix-store --query --requisites "$system_config")
          ${nix}/bin/nix-store --export "''${closure_paths[@]}" > "$closure_file"
          printf -v rsync_ssh '%q ' ${escapeShellArg "${openssh}/bin/ssh"} "''${ssh_args[@]}"
          ${rsync}/bin/rsync \
            --compress \
            --partial \
            --append-verify \
            --progress \
            -e "$rsync_ssh" \
            "$closure_file" \
            "$target:$remote_closure"

          # Variables in this template intentionally expand on the remote host.
          # shellcheck disable=SC2016
          remote_activation_script=$(printf 'set -euo pipefail\nsystem_config=%q\nclosure_file=%q\ncleanup() { rm -f "$closure_file"; }\ntrap cleanup EXIT\nsudo -v\nsudo /nix/var/nix/profiles/default/bin/nix-store --option require-sigs false --import < "$closure_file"\nsudo /nix/var/nix/profiles/default/bin/nix-env -p /nix/var/nix/profiles/system --set "$system_config"\nsudo "$system_config/activate"\n' "$system_config" "$remote_closure")
        else
          env NIX_SSHOPTS="$nix_sshopts" ${nix}/bin/nix copy --to "ssh-ng://$target" "$system_config"
          # Variables in this template intentionally expand on the remote host.
          # shellcheck disable=SC2016
          remote_activation_script=$(printf 'system_config=%q\nsudo nix-env -p /nix/var/nix/profiles/system --set "$system_config"\nsudo "$system_config/activate"\n' "$system_config")
        fi

        remote_cmd=$(printf '/bin/zsh -lc %q' "$remote_activation_script")
        activation_ssh_args=("''${ssh_args[@]}")
        if (( ask_sudo_password == 1 )); then
          activation_ssh_args+=(-t)
        fi
        exec ${openssh}/bin/ssh "''${activation_ssh_args[@]}" "$target" "$remote_cmd"
      fi

      nh_args=(
        os
        switch
        path:${escapeShellArg "${repoRoot}"}
        --hostname "$host"
      )

      if [[ -n "$build_host" ]]; then
        nh_args+=(--build-host "$build_host" --use-substitutes)
      fi
      nh_args+=(--target-host "''${target_host:-$host}")
      if (( ask_sudo_password == 0 )); then
        nh_args=(--elevation-strategy=passwordless "''${nh_args[@]}")
      fi
      nh_args+=(--accept-flake-config)
      if (( dry_run == 1 )); then
        nh_args+=(--dry)
      fi

      exec env NIX_SSHOPTS="$nix_sshopts" ${nh}/bin/nh "''${nh_args[@]}"
    fi

    if [[ "$class" == "darwin" ]]; then
      if (( dry_run == 1 )); then
        exec ${nh}/bin/nh darwin switch path:${escapeShellArg "${repoRoot}"} --hostname "$host" --accept-flake-config --dry
      fi
      exec sudo "''${sudo_args[@]}" ${darwinRebuild} switch --flake ${escapeShellArg "${repoRoot}"}#"$host"
    fi

    nh_args=(
      os
      switch
      path:${escapeShellArg "${repoRoot}"}
      --hostname "$host"
      --accept-flake-config
    )
    if (( dry_run == 1 )); then
      nh_args+=(--dry)
    fi
    exec ${nh}/bin/nh "''${nh_args[@]}"
  '';

  meta = {
    description = "Apply this flake to a local or remote nix-darwin or NixOS host";
    mainProgram = "apply";
    platforms = lib.platforms.unix;
  };
}
