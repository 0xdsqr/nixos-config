{
  hostDefinitions,
  lib,
  runCommandLocal,
  writeShellApplication,
}:
let
  fakePackage =
    names:
    runCommandLocal "apply-fake-tools" { } ''
      mkdir -p "$out/bin"
      ${lib.concatMapStringsSep "\n" (name: ''
        cp ${
          writeShellApplication {
            inherit name;
            text = ''
              {
                printf 'COMMAND=%s\n' ${lib.escapeShellArg name}
                printf 'NIX_SSHOPTS=%s\n' "''${NIX_SSHOPTS:-}"
                printf 'ARG=%s\n' "$@"
              } >> "''${APPLY_TEST_LOG:?APPLY_TEST_LOG is required}"
            '';
          }
        }/bin/${name} "$out/bin/${name}"
      '') names}
    '';

  fakeNix = fakePackage [
    "nix"
    "nix-env"
    "nix-store"
  ];
  fakeNixosRebuild = fakePackage [ "nixos-rebuild" ];
  fakeOpenSsh = fakePackage [ "ssh" ];
  fakeRsync = fakePackage [ "rsync" ];

  testApply = import ./package.nix {
    darwin-rebuild = null;
    inherit hostDefinitions lib writeShellApplication;
    nix = fakeNix;
    nixos-rebuild = fakeNixosRebuild;
    openssh = fakeOpenSsh;
    repoRoot = "/repo";
    rsync = fakeRsync;
  };
in
runCommandLocal "apply-cli-test" { } ''
  export APPLY_TEST_LOG="$TMPDIR/apply.log"

  ${testApply}/bin/apply --build-host srv-lx-khaos srv-lx-k8s-master-01
  printf '%s\n' \
    'COMMAND=nixos-rebuild' \
    'NIX_SSHOPTS=-o ServerAliveInterval=60 -o ServerAliveCountMax=20' \
    'ARG=switch' \
    'ARG=--flake' \
    'ARG=path:/repo#srv-lx-k8s-master-01' \
    'ARG=--target-host' \
    'ARG=srv-lx-k8s-master-01' \
    'ARG=--sudo' \
    'ARG=--no-reexec' \
    'ARG=--use-substitutes' \
    'ARG=--accept-flake-config' \
    'ARG=--build-host' \
    'ARG=srv-lx-khaos' > "$TMPDIR/expected.log"
  diff -u "$TMPDIR/expected.log" "$APPLY_TEST_LOG"

  : > "$APPLY_TEST_LOG"
  ${testApply}/bin/apply \
    --target-host deploy@edge-alias \
    --build-host build@srv-lx-khaos \
    --identity "$TMPDIR/key file" \
    --ask-sudo-password \
    --dry-run \
    srv-lx-k8s-master-01
  grep -Fx 'ARG=deploy@edge-alias' "$APPLY_TEST_LOG"
  grep -Fx 'ARG=build@srv-lx-khaos' "$APPLY_TEST_LOG"
  grep -Fx 'ARG=--ask-sudo-password' "$APPLY_TEST_LOG"
  grep -Fx 'ARG=--no-reexec' "$APPLY_TEST_LOG"
  grep -F 'key\ file' "$APPLY_TEST_LOG"

  if ${testApply}/bin/apply --build-host; then
    echo 'missing option operands must fail' >&2
    exit 1
  fi
  if ${testApply}/bin/apply srv-lx-k8s-master-01 extra; then
    echo 'extra positional arguments must fail' >&2
    exit 1
  fi
  if ${testApply}/bin/apply --remote --build-host srv-lx-khaos srv-lx-k8s-master-01; then
    echo 'conflicting deployment modes must fail' >&2
    exit 1
  fi
  if ${testApply}/bin/apply --remote --remote-root / srv-lx-k8s-master-01; then
    echo 'unsafe remote roots must fail' >&2
    exit 1
  fi

  touch "$out"
''
