{
  lib,
  buildNpmPackage,
  pi-skills-src,
}:
buildNpmPackage {
  pname = "pi-skill-browser-tools";
  version = pi-skills-src.shortRev or "unstable";

  src = "${pi-skills-src}/browser-tools";

  npmDepsHash = "sha256-CRCAVRYM6v7aPnj+F5pLGw7pYNdO3YSSFhGbxVAPW8A=";

  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  env = {
    PUPPETEER_SKIP_DOWNLOAD = "true";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Pi skill: Chrome DevTools browser automation";
    homepage = "https://github.com/badlogic/pi-skills";
    license = lib.licenses.mit;
  };
}
