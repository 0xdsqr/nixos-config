{
  lib,
  stdenvNoCC,
  anthropic-skills-src,
}:
stdenvNoCC.mkDerivation {
  pname = "anthropic-skill-pdf";
  version = anthropic-skills-src.shortRev or "unstable";

  src = "${anthropic-skills-src}/skills/pdf";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Anthropic skill: PDF document handling";
    homepage = "https://github.com/anthropics/skills";
    license = lib.licenses.mit;
  };
}
