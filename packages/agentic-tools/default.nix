{ callPackage, pi-skills-src }:
{
  browser-tools = callPackage ./pi-skill-browser-tools.nix { inherit pi-skills-src; };
  vscode = callPackage ./pi-skill-vscode.nix { inherit pi-skills-src; };
}
