{
  codex,
  fetchFromGitHub,
  rustPlatform,
}:
let
  version = "0.147.0";

  src = fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${version}";
    hash = "sha256-NKeOxp9vLcx7tpghqhpS3ocPqUDP2PircNwkJNpHBPo=";
  };

  cargoHash = "sha256-MJuM2QLxvL+r/Gw8QXLjtsLS25QGVCqcqU5GJssSoQ4=";
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
    for webrtcBuildScript in $cargoDepsCopy/*/webrtc-sys-*/build.rs; do
      if [ -f "$webrtcBuildScript" ]; then
        substituteInPlace "$webrtcBuildScript" \
          --replace-fail "cargo:rustc-link-lib=static=webrtc" "cargo:rustc-link-lib=dylib=webrtc"
      fi
    done
    substituteInPlace Cargo.toml \
      --replace-quiet 'lto = "fat"' "" \
      --replace-quiet 'codegen-units = 1' ""
  '';
})
