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
            claudeCodeVersion = "2.1.154";
            claudeCodePlatformKey = "${prev.stdenvNoCC.hostPlatform.node.platform}-${prev.stdenvNoCC.hostPlatform.node.arch}";
            claudeCodeChecksums = {
              darwin-arm64 = "sha256-vJiBsQfXvhdDxkyLct1meY9dCUfbxI7Q13lkxHNmH9Q=";
              darwin-x64 = "sha256-FgjZMmGHkgHc933TLcFz777qcVGH01Qv0Fr899W17E0=";
              linux-arm64 = "sha256-n3Mt4nj3rcYdKf1bBV3a8brjuybXX+bgahJWAlZXd6g=";
              linux-x64 = "sha256-Z/bKt+bBJAEPYqwY+AeLwJ4NtqW56K6HTp5zAzxFF5M=";
            };
            codexVersion = "0.134.0";
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
              src = prev.fetchFromGitHub {
                owner = "openai";
                repo = "codex";
                tag = "rust-v${codexVersion}";
                hash = "sha256-eHe4bjUIvSK512ZTlFcOBqv5hhM+zfzkxcLfrzDA7L4=";
              };
              cargoHash = "sha256-DjqTn6DWfOlwdQ387eWeT5fs6qIgaD2rAXjxNStKgrs=";
            });
          }
        )
      ];
  };
}
