{
  codex,
  fetchFromGitHub,
  fetchurl,
  rustPlatform,
  stdenv,
}:
let
  version = "0.148.0";
  rustyV8Version = "150.4.0";

  src = fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${version}";
    hash = "sha256-Au61OzWJgYoQFHjV6LHCXTVfwN5AF3+MjdN5FLYhLYI=";
  };

  cargoHash = "sha256-MswemCvyG7uju6QrGKsZoD4S1GUhB8fP38o0R0mPa2M=";

  rustyV8Archive = fetchurl {
    name = "librusty_v8-${rustyV8Version}";
    url = "https://github.com/denoland/rusty_v8/releases/download/v${rustyV8Version}/librusty_v8_release_${stdenv.hostPlatform.rust.rustcTarget}.a.gz";
    sha256 =
      {
        x86_64-linux = "0v5hi3s56b6yk7nh5n0wygh7fn0j41yyjz5903r227qv0yvzssaq";
        aarch64-linux = "1lvx9xjzv7ibqvg5jnaxqaaim0lw4dwfgf6kw0pjfdrkmm97s5xp";
        aarch64-darwin = "043bgs3hcvrn1yzknrxchqnki8r9p7ggk9zbiaqwa8mqhlagin6c";
      }
      .${stdenv.hostPlatform.system};
  };

  rustyV8SrcBinding = fetchurl {
    name = "src_binding-${rustyV8Version}";
    url = "https://github.com/denoland/rusty_v8/releases/download/v${rustyV8Version}/src_binding_release_${stdenv.hostPlatform.rust.rustcTarget}.rs";
    sha256 =
      {
        x86_64-linux = "01l53l6nk4p5brpz2v3svqijx3hz5nqry8q7x12vdgbrwim849vp";
        aarch64-linux = "01l53l6nk4p5brpz2v3svqijx3hz5nqry8q7x12vdgbrwim849vp";
        aarch64-darwin = "0krrb2vh4skvfmzwpcqkl55bg2gyn943drqa8snp16lwz06dynna";
      }
      .${stdenv.hostPlatform.system};
  };
in
codex.overrideAttrs (old: {
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

  env = (old.env or { }) // {
    RUSTY_V8_ARCHIVE = rustyV8Archive;
    RUSTY_V8_SRC_BINDING_PATH = rustyV8SrcBinding;
  };
})
