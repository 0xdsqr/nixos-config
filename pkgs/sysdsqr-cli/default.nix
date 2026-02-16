{
  lib,
  buildGoModule,
}:
buildGoModule {
  pname = "sysdsqr";
  version = "0.1.0";

  src = ./.;

  vendorHash = null;

  meta = with lib; {
    description = "System admin CLI for dsqr homelab";
    homepage = "https://github.com/0xdsqr/nixos-config";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
