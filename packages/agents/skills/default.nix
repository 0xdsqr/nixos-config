{ inputs }: {
  git-workflow = ./git-workflow;
  greptile-review = ./greptile-review;
  i-have-adhd = inputs.i-have-adhd + "/skills/i-have-adhd";

  # Official Effect skills (https://github.com/Effect-TS/skills). `effect-ts`
  # points agents at the AGENTS.md shipped with the installed `effect` package;
  # `effect-v3-to-v4` is a manual-only migration workflow.
  effect-ts = inputs.effect-skills + "/skills/effect-ts";
  effect-v3-to-v4 = inputs.effect-skills + "/skills/effect-v3-to-v4";
}
