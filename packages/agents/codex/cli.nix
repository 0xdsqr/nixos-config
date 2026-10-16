{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  makeBinaryWrapper,
  ripgrep,
  bubblewrap,
}:
let
  version = "0.163.0";

  # Upstream's prebuilt release binaries; building from source took ~2h on CI.
  hashes = {
    aarch64-darwin = "sha256-YcTZqSUhvbQrDB2fh8Zz9tpiigbeWUXL3ZoAEGMvbRA=";
    x86_64-linux = "sha256-vrM56OzZugV6a7Lcga2MpHSBLt+/D8UFbKgYeXZI3eQ=";
    aarch64-linux = "sha256-pyYeZfSpbY9MploGnGzy3Cwz3vw0HkgHis79qUYf/+Q=";
  };
  targets = {
    aarch64-darwin = "aarch64-apple-darwin";
    x86_64-linux = "x86_64-unknown-linux-musl";
    aarch64-linux = "aarch64-unknown-linux-musl";
  };

  inherit (stdenvNoCC.hostPlatform) system;
  target = targets.${system} or (throw "codex: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-${target}.tar.gz";
    hash = hashes.${system};
  };
  sourceRoot = ".";

  nativeBuildInputs = [
    installShellFiles
    makeBinaryWrapper
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 codex-${target} $out/bin/codex
    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    installShellCompletion --cmd codex \
      --bash <($out/bin/codex completion bash) \
      --fish <($out/bin/codex completion fish) \
      --zsh <($out/bin/codex completion zsh)
  '';

  postFixup = ''
    wrapProgram $out/bin/codex --prefix PATH : ${
      lib.makeBinPath ([ ripgrep ] ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ bubblewrap ])
    }
  '';

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames targets;
    mainProgram = "codex";
  };
}
