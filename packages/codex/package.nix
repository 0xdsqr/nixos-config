{
  codex,
  fetchFromGitHub,
  rustPlatform,
}:
let
  version = "0.143.0";

  src = fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${version}";
    hash = "sha256-4xJcE8/lFwp1r/J8z7HMb7A59WXkj3rtm9QDtjJfC04=";
  };

  cargoHash = "sha256-YUQYPo4joZwHlderRA4f5A/04+rI+R1jd7RsfA5+P1E=";
in
codex.overrideAttrs (_: {
  inherit version src cargoHash;

  cargoDeps = rustPlatform.fetchCargoVendor {
    pname = "codex";
    inherit version src;
    sourceRoot = "${src.name}/codex-rs";
    hash = cargoHash;
  };

  # Upstream's postPatch strips `lto`/`codegen-units` with --replace-fail; recent
  # codex dropped those, so keep the webrtc-sys link fix but make the tweaks no-op.
  postPatch = ''
    substituteInPlace $cargoDepsCopy/*/webrtc-sys-*/build.rs \
      --replace-fail "cargo:rustc-link-lib=static=webrtc" "cargo:rustc-link-lib=dylib=webrtc"
    substituteInPlace Cargo.toml \
      --replace-quiet 'lto = "fat"' "" \
      --replace-quiet 'codegen-units = 1' ""
  '';
})
