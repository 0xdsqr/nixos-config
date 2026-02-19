{
  lib,
  buildGoModule,
}:
let
  version = "0.1.0";
in
buildGoModule {
  pname = "sysdsqr";
  inherit version;

  src = ./.;
  subPackages = [ "cmd/dsqr" ];
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  vendorHash = null;

  postInstall = ''
    ln -s "$out/bin/dsqr" "$out/bin/sysdsqr"
  '';

  meta = with lib; {
    description = "System admin CLI for dsqr homelab";
    homepage = "https://github.com/0xdsqr/nixos-config";
    license = licenses.mit;
    mainProgram = "dsqr";
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
