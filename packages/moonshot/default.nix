{ buildGoModule, lib }:
let
  pname = "moonshot";
  version = "0.0.0-sandbox.0";
  src = ./.;

  subPackages = [ "./cmd/moonshot" ];

  description = "Moonshot CLI";
  mainProgram = "moonshot";
in
buildGoModule {
  inherit
    pname
    version
    src
    subPackages
    ;

  ldflags = [ "-X github.com/0xdsqr/moonshot/internal/version.Value=${version}" ];

  # Pin the Go module dependency graph so builds stay fully offline.
  vendorHash = "sha256-ad//bCpgy4DfL35U6voHPpwNE93YTMdJoyI2+Vpn1mU=";

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
