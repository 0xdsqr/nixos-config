{
  lib,
  openssh,
  rsync,
  writeShellScriptBin,
  hostDefinitions ? { },
  repoRoot ? ../..,
}:
let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) concatStringsSep escapeShellArg;

  hostCases = concatStringsSep "\n" (
    mapAttrsToList (
      hostName: hostMeta:
      let
        class = hostMeta.class or (throw "packages.apply: hostDefinitions.${hostName}.class is required");
        sshHost = hostMeta.sshHost or null;
        target = if sshHost == null then hostName else sshHost;
      in
      /* bash */ ''
        ${hostName})
          class=${escapeShellArg class}
          target=${escapeShellArg target}
          ;;
      ''
    ) hostDefinitions
  );

  hostTargets = concatStringsSep "\n" (
    mapAttrsToList (
      hostName: hostMeta:
      let
        sshHost = hostMeta.sshHost or null;
        target = if sshHost == null then hostName else sshHost;
      in
      /* bash */ ''
        ${hostName})
          printf '%s\n' ${escapeShellArg target}
          ;;
      ''
    ) hostDefinitions
  );
in
(writeShellScriptBin "apply" /* bash */ ''
  set -euo pipefail

  host=""
  build_host=""
  target_host_override=""
  remote=0
  remote_root="~/nixos-config"
  identity_file="''${APPLY_SSH_IDENTITY:-}"
  ask_elevate_password=0

  usage() {
    cat <<'EOF'
  usage: apply [options] <host>

    apply <host>
        Apply the local flake to the current machine.

    apply --remote <host>
        Sync this repo to the target host and apply there.

    apply --build-host <host> <host>
        Build on the given NixOS host, then activate the target host.

    apply --target-host <host> <darwin-host>
        Build locally, copy the closure to the Darwin target host, then activate it.

  options:
    --remote
    --build-host <host>
    --target-host <host>
    --identity <path>
    --remote-root <path>
    --ask-elevate-password
  EOF
  }

  resolve_target() {
    local value="$1"
    local user_prefix=""
    local name="$value"

    if [[ "$value" == *@* ]]; then
      user_prefix="''${value%@*}@"
      name="''${value#*@}"
    fi

    case "$name" in
  ${hostTargets}
      *)
        printf '%s\n' "$name"
        ;;
    esac | while IFS= read -r resolved; do
      printf '%s%s\n' "$user_prefix" "$resolved"
    done
  }

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remote)
        remote=1
        shift
        ;;
      --build-host)
        build_host="$2"
        shift 2
        ;;
      --target-host)
        target_host_override="$2"
        shift 2
        ;;
      --identity)
        identity_file="$2"
        shift 2
        ;;
      --remote-root)
        remote_root="$2"
        shift 2
        ;;
      --ask-elevate-password|--ask-sudo-password)
        ask_elevate_password=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "unknown flag: $1" >&2
        exit 1
        ;;
      *)
        if [[ -z "$host" ]]; then
          host="$1"
          shift
        else
          break
        fi
        ;;
    esac
  done

  if [[ -z "$host" ]]; then
    usage >&2
    exit 1
  fi

  case "$host" in
  ${hostCases}
    *)
      echo "unknown host: $host" >&2
      exit 1
      ;;
  esac

  if [[ "$remote" -eq 1 && ( -n "$build_host" || -n "$target_host_override" ) ]]; then
    echo "--remote cannot be combined with --build-host or --target-host" >&2
    exit 1
  fi

  ssh_args=()
  nix_sshopts="''${NIX_SSHOPTS:-}"
  sudo_args=()
  if [[ -n "$identity_file" ]]; then
    ssh_args+=(-i "$identity_file" -o IdentitiesOnly=yes)
    nix_sshopts+=" -i $identity_file -o IdentitiesOnly=yes"
  fi
  if [[ -n "''${NIX_CONFIG:-}" ]]; then
    sudo_args+=(--preserve-env=NIX_CONFIG)
  fi

  if [[ "$remote" -eq 1 ]]; then
    if [[ "$class" == "darwin" ]]; then
      remote_cmd="cd \"$remote_root\"; sudo darwin-rebuild switch --flake path:.#$host"
    else
      remote_cmd="cd \"$remote_root\"; sudo nix --accept-flake-config run nixpkgs#nixos-rebuild -- switch --flake path:.#$host"
    fi

    ${rsync}/bin/rsync \
      --archive \
      --compress \
      --delete \
      --exclude .git \
      -e "${openssh}/bin/ssh ''${ssh_args[*]}" \
      ${escapeShellArg "${repoRoot}/"} \
      "$target:$remote_root/"

    exec ${openssh}/bin/ssh "''${ssh_args[@]}" "$target" "$remote_cmd"
  fi

  if [[ -n "$build_host" || -n "$target_host_override" ]]; then
    if [[ "$class" == "darwin" ]]; then
      if [[ -n "$build_host" ]]; then
        echo "--build-host deployments are only supported for NixOS hosts" >&2
        exit 1
      fi

      target_resolved="$(resolve_target "''${target_host_override:-$target}")"
      system_config="$(
        nix --accept-flake-config build \
          --no-link \
          --print-out-paths \
          ${escapeShellArg "${repoRoot}"}#darwinConfigurations."$host".system
      )"

      env NIX_SSHOPTS="$nix_sshopts" nix copy --to "ssh-ng://$target_resolved" "$system_config"

      remote_activation_script=$(printf 'system_config=%q\nsudo nix-env -p /nix/var/nix/profiles/system --set "$system_config"\nsudo "$system_config/activate"\n' "$system_config")
      remote_cmd=$(printf '/bin/zsh -lc %q' "$remote_activation_script")
      activation_ssh_args=("''${ssh_args[@]}")
      if [[ "$ask_elevate_password" -eq 1 ]]; then
        activation_ssh_args+=(-t)
      fi

      exec ${openssh}/bin/ssh "''${activation_ssh_args[@]}" "$target_resolved" "$remote_cmd"
    fi

    rebuild_args=(
      switch
      --flake path:${escapeShellArg "${repoRoot}"}#"$host"
      --target-host "$(resolve_target "''${target_host_override:-$target}")"
      --elevate=sudo
      --use-substitutes
      --accept-flake-config
    )

    if [[ -n "$build_host" ]]; then
      rebuild_args+=(--build-host "$(resolve_target "$build_host")")
    fi

    if [[ "$ask_elevate_password" -eq 1 ]]; then
      rebuild_args+=(--ask-elevate-password)
    fi

    exec env NIX_SSHOPTS="$nix_sshopts" nix --accept-flake-config run nixpkgs#nixos-rebuild -- "''${rebuild_args[@]}"
  fi

  if [[ "$class" == "darwin" ]]; then
    exec sudo "''${sudo_args[@]}" darwin-rebuild switch --flake ${escapeShellArg "${repoRoot}"}#"$host"
  fi

  exec sudo "''${sudo_args[@]}" nix --accept-flake-config run nixpkgs#nixos-rebuild -- switch --flake path:${escapeShellArg "${repoRoot}"}#"$host"
'').overrideAttrs
  (oldAttrs: {
    meta = (oldAttrs.meta or { }) // {
      description = "Apply this flake to a local or remote nix-darwin or NixOS host";
      mainProgram = "apply";
      platforms = lib.platforms.unix;
    };
  })
