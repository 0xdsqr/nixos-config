{
  lib,
  stdenvNoCC,
  anthropic-skills-src,
}:
stdenvNoCC.mkDerivation {
  pname = "anthropic-skill-skill-creator";
  version = anthropic-skills-src.shortRev or "unstable";

  src = "${anthropic-skills-src}/skills/skill-creator";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Anthropic skill: scaffolding for authoring new agent skills";
    homepage = "https://github.com/anthropics/skills";
    license = lib.licenses.mit;
  };
}
