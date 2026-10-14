{ inputs }: {
  git-workflow = ./git-workflow;
  greptile-review = ./greptile-review;
  i-have-adhd = inputs.i-have-adhd + "/skills/i-have-adhd";
}
