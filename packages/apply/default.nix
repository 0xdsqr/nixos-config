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
in
(writeShellScriptBin "apply" /* bash */ ''
  set -euo pipefail

  host=""
  remote=0
  remote_root="~/nixos-config"
  identity_file="''${APPLY_SSH_IDENTITY:-}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remote)
        remote=1
        shift
        ;;
      --identity)
        identity_file="$2"
        shift 2
        ;;
      --remote-root)
        remote_root="$2"
        shift 2
        ;;
      --help|-h)
        cat <<'EOF'
  usage: apply [--remote] [--identity <path>] [--remote-root <path>] <host>

    apply <host>             Apply the local flake to the current machine.
    apply --remote <host>    Sync this repo to the target host and apply there.
  EOF
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
    echo "usage: apply [--remote] [--identity <path>] [--remote-root <path>] <host>" >&2
    exit 1
  fi

  case "$host" in
  ${hostCases}
    *)
      echo "unknown host: $host" >&2
      exit 1
      ;;
  esac

  ssh_args=()
  if [[ -n "$identity_file" ]]; then
    ssh_args+=(-i "$identity_file" -o IdentitiesOnly=yes)
  fi

  if [[ "$remote" -eq 1 ]]; then
    if [[ "$class" == "darwin" ]]; then
      remote_cmd="cd \"$remote_root\"; sudo darwin-rebuild switch --flake .#$host"
    else
      remote_cmd="cd \"$remote_root\"; sudo nix --accept-flake-config run nixpkgs#nixos-rebuild -- switch --flake .#$host"
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

  if [[ "$class" == "darwin" ]]; then
    exec sudo darwin-rebuild switch --flake ${escapeShellArg "${repoRoot}"}#"$host"
  fi

  exec sudo nix --accept-flake-config run nixpkgs#nixos-rebuild -- switch --flake path:${escapeShellArg "${repoRoot}"}#"$host"
'').overrideAttrs
  (oldAttrs: {
    meta = (oldAttrs.meta or { }) // {
      description = "Apply this flake to a local or remote nix-darwin or NixOS host";
      mainProgram = "apply";
      platforms = lib.platforms.unix;
    };
  })
