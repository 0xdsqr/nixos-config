{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "xurl";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "xdevplatform";
    repo = "xurl";
    rev = "v${version}";
    hash = "sha256-dwVBzuUhQpfRWFOZOf1DCGNKoetdZlcretnyv9AShbw=";
  };

  patches = [ ./least-privilege-scopes.patch ];

  postPatch = ''
    substituteInPlace api/client_test.go \
      --replace-fail '"xurl/dev"' '"xurl/${version}"'
  '';

  vendorHash = "sha256-3yUZZYHcDpCaK55uiVw4X9mxvda9iL+XwPpSXheKOSc=";

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/xdevplatform/xurl/version.Version=${version}"
  ];

  meta = {
    description = "Official command-line interface for the X API";
    homepage = "https://github.com/xdevplatform/xurl";
    license = lib.licenses.asl20;
    mainProgram = "xurl";
  };
}
