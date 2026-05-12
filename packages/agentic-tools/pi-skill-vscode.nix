{
  lib,
  stdenvNoCC,
  pi-skills-src,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-skill-vscode";
  version = pi-skills-src.shortRev or "unstable";

  src = "${pi-skills-src}/vscode";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Pi skill: VS Code integration for diffs and file comparison";
    homepage = "https://github.com/badlogic/pi-skills";
    license = lib.licenses.mit;
  };
}
