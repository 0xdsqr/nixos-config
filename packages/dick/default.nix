{ buildGoModule, lib }:
let
  pname = "dick";
  version = "0.0.0-sandbox.0";
  src = ./.;

  subPackages = [ "./cmd/dick" ];

  description = "Dick CLI";
  mainProgram = "dick";
in
buildGoModule {
  inherit
    pname
    version
    src
    subPackages
    ;

  ldflags = [ "-X github.com/0xdsqr/dick/internal/version.Value=${version}" ];

  # Pin the Go module dependency graph so builds stay fully offline.
  vendorHash = "sha256-FzPCkb9V7q6Sxr59FisavMcFOxUIpr31wIfkYW92JlU=";

  doCheck = true;

  # buildGoModule handles the normal Go build pipeline for us.
  # These are the raw phase hook shapes we would customize with mkDerivation:
  #
  # unpackPhase = ''
  #   runHook preUnpack
  #   runHook postUnpack
  # '';
  #
  # patchPhase = ''
  #   runHook prePatch
  #   runHook postPatch
  # '';
  #
  # configurePhase = ''
  #   runHook preConfigure
  #   runHook postConfigure
  # '';
  #
  # buildPhase = ''
  #   runHook preBuild
  #   runHook postBuild
  # '';
  #
  # checkPhase = ''
  #   runHook preCheck
  #   runHook postCheck
  # '';
  #
  # installPhase = ''
  #   runHook preInstall
  #   runHook postInstall
  # '';
  #
  # fixupPhase = ''
  #   runHook preFixup
  #   runHook postFixup
  # '';

  meta = {
    inherit description mainProgram;
    platforms = lib.platforms.all;
  };
}
