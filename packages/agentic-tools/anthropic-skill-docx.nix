{
  lib,
  stdenvNoCC,
  anthropic-skills-src,
}:
stdenvNoCC.mkDerivation {
  pname = "anthropic-skill-docx";
  version = anthropic-skills-src.shortRev or "unstable";

  src = "${anthropic-skills-src}/skills/docx";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Anthropic skill: Word document manipulation";
    homepage = "https://github.com/anthropics/skills";
    license = lib.licenses.mit;
  };
}
