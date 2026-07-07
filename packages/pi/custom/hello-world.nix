{ runCommand, writeText }:
let
  skillMd = writeText "SKILL.md" /* markdown */ ''
    ---
    name: hello-world
    description: Example custom skill scaffold — copy this file and replace the body with your own workflow
    ---

    # Hello World

    This is a placeholder custom skill. When invoked via `/skill:hello-world`,
    the agent loads this document and follows whatever instructions it contains.

    Replace this body with step-by-step guidance for the task you want the
    agent to perform. You can also drop helper scripts, reference docs, or
    assets into the same directory and reference them by relative path.

    See `packages/pi/custom/hello-world.nix` for the Nix wrapper — clone
    it for your next custom skill.
  '';
in
runCommand "custom-skill-hello-world" { } /* bash */ ''
  mkdir -p $out
  cp ${skillMd} $out/SKILL.md
''
