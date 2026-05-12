{
  callPackage,
  pi-skills-src,
  anthropic-skills-src,
}:
{
  browser-tools = callPackage ./pi-skill-browser-tools.nix { inherit pi-skills-src; };
  vscode = callPackage ./pi-skill-vscode.nix { inherit pi-skills-src; };

  pdf = callPackage ./anthropic-skill-pdf.nix { inherit anthropic-skills-src; };
  docx = callPackage ./anthropic-skill-docx.nix { inherit anthropic-skills-src; };
  pptx = callPackage ./anthropic-skill-pptx.nix { inherit anthropic-skills-src; };
  xlsx = callPackage ./anthropic-skill-xlsx.nix { inherit anthropic-skills-src; };
  skill-creator = callPackage ./anthropic-skill-skill-creator.nix { inherit anthropic-skills-src; };

  hello-world = callPackage ./custom-skills/hello-world.nix { };
}
