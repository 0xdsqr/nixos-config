{
  lib,
  stdenvNoCC,
  anthropic-skills-src,
}:
stdenvNoCC.mkDerivation {
  pname = "anthropic-skill-pptx";
  version = anthropic-skills-src.shortRev or "unstable";

  src = "${anthropic-skills-src}/skills/pptx";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Anthropic skill: PowerPoint presentation creation";
    homepage = "https://github.com/anthropics/skills";
    license = lib.licenses.mit;
  };
}
