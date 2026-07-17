{
  lib,
  buildNpmPackage,
  callPackage,
  curl,
  nodejs_22,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  manifest = import ./manifest.nix;

  piSkillsRev = "90bb51cae36515a648515b633a81c0c6efc8c74d";
  piSkillsHash = "sha256-NcaMKdbADZhlnEMTl3pQON9WayBdCjFRHH+dBNOJ+mk=";
  anthropicSkillsRev = "fa0fa64bdc967915dc8399e803be67759e1e62b8";
  anthropicSkillsHash = "sha256-QZ+zJkyLd/42rxgtJEZSUOz9R75Tse6UXW7G0nOkFS8=";
  browserToolsNpmDepsHash = "sha256-CRCAVRYM6v7aPnj+F5pLGw7pYNdO3YSSFhGbxVAPW8A=";
  braveSearchNpmDepsHash = "sha256-E6EJKin0ATPlZp9MYxeg5S5kay0x+2J1zQnkTtBQwc0=";

  npmDepsHashes = {
    browser-tools = browserToolsNpmDepsHash;
    brave-search = braveSearchNpmDepsHash;
  };

  pi-skills-src = fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-skills";
    rev = piSkillsRev;
    hash = piSkillsHash;
  };

  anthropic-skills-src = fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = anthropicSkillsRev;
    hash = anthropicSkillsHash;
  };

  installSkill = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  mkStaticSkill =
    {
      pname,
      version,
      src,
      description,
      homepage,
      postInstall ? "",
    }:
    stdenvNoCC.mkDerivation {
      inherit
        pname
        version
        src
        postInstall
        ;

      dontConfigure = true;
      dontBuild = true;

      installPhase = installSkill;

      meta = {
        inherit description homepage;
        license = lib.licenses.mit;
      };
    };

  mkPiStaticSkill =
    name: info:
    mkStaticSkill {
      pname = "pi-skill-${name}";
      version = pi-skills-src.shortRev or "unstable";
      src = "${pi-skills-src}/${name}";
      inherit (info) description;
      homepage = "https://github.com/badlogic/pi-skills";
      postInstall = lib.optionalString (name == "transcribe") ''
        patchShebangs --host "$out/transcribe.sh"
        substituteInPlace "$out/transcribe.sh" \
          --replace-quiet "curl " "${curl}/bin/curl "
      '';
    };

  mkPiNpmSkill =
    name: info:
    buildNpmPackage {
      pname = "pi-skill-${name}";
      version = pi-skills-src.shortRev or "unstable";

      src = "${pi-skills-src}/${name}";
      npmDepsHash = npmDepsHashes.${name};

      nodejs = nodejs_22;
      dontNpmBuild = true;
      npmFlags = [ "--ignore-scripts" ];
      npmRebuildFlags = [ "--ignore-scripts" ];

      env.PUPPETEER_SKIP_DOWNLOAD = "true";

      postPatch = ''
        for script in ./*.js; do
          [ -e "$script" ] || continue
          patchShebangs --build "$script"
        done
      '';

      installPhase = installSkill;

      meta = {
        inherit (info) description;
        homepage = "https://github.com/badlogic/pi-skills";
        license = lib.licenses.mit;
      };
    };

  mkPiSkill = name: info: if info.kind == "npm" then mkPiNpmSkill name info else mkPiStaticSkill name info;

  mkAnthropicSkill =
    name: info:
    mkStaticSkill {
      pname = "anthropic-skill-${name}";
      version = anthropic-skills-src.shortRev or "unstable";
      src = "${anthropic-skills-src}/skills/${name}";
      inherit (info) description;
      homepage = "https://github.com/anthropics/skills";
    };

  hello-world = callPackage ./custom/hello-world.nix { };
in
lib.mapAttrs mkPiSkill manifest.pi // lib.mapAttrs mkAnthropicSkill manifest.anthropic // { inherit hello-world; }
