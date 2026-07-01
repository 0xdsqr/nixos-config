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
            claudeCodeVersion = "2.1.197";
            claudeCodePlatformKey = "${prev.stdenvNoCC.hostPlatform.node.platform}-${prev.stdenvNoCC.hostPlatform.node.arch}";
            claudeCodeChecksums = {
              darwin-arm64 = "sha256-jMDE0eTrHco7DMkqsC7jUF3nZOAj+MkBdhwWe3IEH7g=";
              darwin-x64 = "sha256-XopXzHqSN38HRPpMeRkc+T1LJsecuRmwekB1Ef7RviY=";
              linux-arm64 = "sha256-+0hHPEZ8J2Fax5mnVPTvC2jDY+RZbO+7WcOBXVGgzIo=";
              linux-x64 = "sha256-9U5py8ibLaYaQVcAr3/1KhR+hiUX1PGw7s92hEjPf4M=";
            };
            codexVersion = "0.142.5";
            codexSrc = prev.fetchFromGitHub {
              owner = "openai";
              repo = "codex";
              tag = "rust-v${codexVersion}";
              hash = "sha256-Ua1UVArTvjHcg3bPK1FYyShYiIUH3AOxtoUTvA4UZwU=";
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
                hash = "sha256-1gDiCB3Nf/0aIm+EoL3g9C0xbCi3cv6TfH5VytjJpOY=";
              };
              cargoHash = "sha256-1gDiCB3Nf/0aIm+EoL3g9C0xbCi3cv6TfH5VytjJpOY=";

              # Upstream nixpkgs' postPatch strips `lto = "fat"` / `codegen-units = 1`
              # from the release profile with --replace-fail. codex 0.142.5 already
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
