{ inputs, ... }:
{
  flake.commonModules.nixpkgs = _: {
    nixpkgs.overlays =
      builtins.map (name: inputs.${name}.overlays.default) [
        "agenix"
        "darwin"
        "neovim-nightly-overlay"
      ]
      ++ [
        (
          _: prev:
          let
            claudeCodeVersion = "2.1.170";
            claudeCodePlatformKey = "${prev.stdenvNoCC.hostPlatform.node.platform}-${prev.stdenvNoCC.hostPlatform.node.arch}";
            claudeCodeChecksums = {
              darwin-arm64 = "sha256-6QNkbYt6MYgqgOzSdWmifYrFezcIdF80lwljLIQRf98=";
              darwin-x64 = "sha256-kU8jpwu+1dmuVn4+BLhiBu2ZcbNxvJuso/eciIW/3bQ=";
              linux-arm64 = "sha256-G7nQMkQKdVMvfdTK+8aH8iCq8Wxj66F+GS377C8EvSU=";
              linux-x64 = "sha256-hJ4AcnegRCqydXDT49bUN4dQeUZZDo3RlH5aObcIH54=";
            };
            codexVersion = "0.139.0";
            codexSrc = prev.fetchFromGitHub {
              owner = "openai";
              repo = "codex";
              tag = "rust-v${codexVersion}";
              hash = "sha256-XjzlkBUkBey+P3tFLDYB3ae5oseUfW5tmzhLzqlqj2E=";
            };
          in
          {
            claude-code = prev.claude-code.overrideAttrs (_: {
              version = claudeCodeVersion;
              src = prev.fetchurl {
                url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${claudeCodeVersion}/${claudeCodePlatformKey}/claude";
                sha256 = claudeCodeChecksums.${claudeCodePlatformKey};
              };
            });

            codex = prev.codex.overrideAttrs (_: {
              version = codexVersion;
              src = codexSrc;
              cargoDeps = prev.rustPlatform.fetchCargoVendor {
                pname = "codex";
                version = codexVersion;
                src = codexSrc;
                sourceRoot = "${codexSrc.name}/codex-rs";
                hash = "sha256-8mN4OTRJvt2mBYHQXZS55PSOChLqEIiXwPu2y+2MZ9o=";
              };
              cargoHash = "sha256-8mN4OTRJvt2mBYHQXZS55PSOChLqEIiXwPu2y+2MZ9o=";

              # Upstream nixpkgs' postPatch strips `lto = "fat"` / `codegen-units = 1`
              # from the release profile with --replace-fail. codex 0.139.0 already
              # ships `lto = "thin"` and dropped codegen-units, so those hard fails
              # abort the build. Keep the load-bearing webrtc-sys link fix, but make
              # the profile tweaks tolerant so they no-op when the patterns are absent.
              postPatch = ''
                substituteInPlace $cargoDepsCopy/*/webrtc-sys-*/build.rs \
                  --replace-fail "cargo:rustc-link-lib=static=webrtc" "cargo:rustc-link-lib=dylib=webrtc"
                substituteInPlace Cargo.toml \
                  --replace-quiet 'lto = "fat"' "" \
                  --replace-quiet 'codegen-units = 1' ""
              '';
            });
          }
        )
      ];
  };
}
