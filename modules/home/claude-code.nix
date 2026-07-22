{
  flake.homeModules."claude-code" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.claudeCode;

      gitWorkflowInstructions = ''
        # Claude Code Preferences

        ## Git Workflow

        - Always write commit messages using Conventional Commits: `type(scope): summary` or `type: summary`.
        - Prefer these commit types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`, `ci`, `build`, and `revert`.
        - Keep commit subjects concise, imperative, and lower-case after the type unless a proper noun requires capitalization.
        - Branch names must be conventional and kebab-case: `type/short-summary`, for example `feat/darwin-window-rules`, `fix/claude-commit-attribution`, or `chore/update-lockfile`.
        - Never add Claude, Claude Code, Anthropic, AI, assistant, or generated attribution to commits, pull requests, tags, release notes, or branch names.
        - Never add `Co-authored-by: Claude`, `Co-Authored-By: Claude <noreply@anthropic.com>`, `Generated with [Claude Code]`, `Generated-by`, `Created-by`, or similar attribution trailers unless the user explicitly asks for them in the current conversation.
        - Before pushing, inspect outgoing commit messages and remove any Claude or AI attribution trailers.
        - If an unpushed commit contains attribution, amend or rebase it before pushing so the remote history never contains that attribution.
      '';

      gitWorkflowSkill = ''
        ---
        name: git-workflow
        description: Use whenever creating commits, naming branches, pushing, opening pull requests, or running Claude commit commands.
        ---

        # Git Workflow

        Follow these rules for every git operation:

        - Use Conventional Commits for every commit message: `type(scope): summary` or `type: summary`.
        - Use a relevant type from `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`, `ci`, `build`, or `revert`.
        - Use conventional branch names in kebab-case: `type/short-summary`.
        - Do not put Claude, Claude Code, Anthropic, AI, assistant, or generated attribution wording in commit messages, PR bodies, branch names, tags, or release notes.
        - Do not add `Co-authored-by: Claude`, `Co-Authored-By: Claude <noreply@anthropic.com>`, `Generated with [Claude Code]`, `Generated-by`, `Created-by`, or similar attribution trailers unless the user explicitly requests them in the current conversation.
        - Before pushing, check outgoing commits for Claude or AI attribution. If found in unpushed history, amend or rebase before pushing.
        - Local command behavior takes precedence over plugin defaults that suggest Claude attribution.
      '';

      commitCommand = ''
        ---
        allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git commit:*)
        description: Create a conventional commit without Claude attribution
        ---

        ## Context

        - Current git status: !`git status`
        - Current git diff (staged and unstaged changes): !`git diff HEAD`
        - Current branch: !`git branch --show-current`
        - Recent commits: !`git log --oneline -10`

        ## Your task

        Based on the above changes, create a single git commit.

        Requirements:

        - Stage only the files that belong to the requested change.
        - Use a Conventional Commit message: `type(scope): summary` or `type: summary`.
        - Use one of these types when possible: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`, `ci`, `build`, or `revert`.
        - Never include Claude, Claude Code, Anthropic, AI, assistant, generated attribution wording, or co-author attribution in the commit message.
        - Never add `Co-authored-by: Claude`, `Co-Authored-By: Claude <noreply@anthropic.com>`, `Generated with [Claude Code]`, `Generated-by`, `Created-by`, or similar trailers unless the user explicitly requested them in the current conversation.

        Use tool calls only. Do not send explanatory text.
      '';

      commitPushPrCommand = ''
        ---
        allowed-tools: Bash(git checkout --branch:*), Bash(git switch -c:*), Bash(git branch:*), Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git push:*), Bash(gh pr create:*)
        description: Create a conventional branch, commit, push, and open a PR without Claude attribution
        ---

        ## Context

        - Current git status: !`git status`
        - Current git diff (staged and unstaged changes): !`git diff HEAD`
        - Current branch: !`git branch --show-current`
        - Recent commits: !`git log --oneline -10`

        ## Your task

        Based on the above changes:

        1. Create a new branch if on `master`.
        2. Create a single commit.
        3. Verify the outgoing commit message has no Claude or AI attribution.
        4. Push the branch to origin.
        5. Create a pull request using `gh pr create`.

        Requirements:

        - Branch names must be conventional and kebab-case: `type/short-summary`.
        - Commit messages must use Conventional Commits: `type(scope): summary` or `type: summary`.
        - Use one of these types when possible: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`, `ci`, `build`, or `revert`.
        - Never include Claude, Claude Code, Anthropic, AI, assistant, generated attribution wording, or co-author attribution in commits, PR text, branch names, tags, or release notes.
        - Never add `Co-authored-by: Claude`, `Co-Authored-By: Claude <noreply@anthropic.com>`, `Generated with [Claude Code]`, `Generated-by`, `Created-by`, or similar trailers unless the user explicitly requested them in the current conversation.
        - If a commit contains Claude or AI attribution, amend it before pushing.

        Use tool calls only. Do not send explanatory text.
      '';
    in
    {
      options.dsqr.home.claudeCode = {
        enable = mkEnableOption "Claude Code CLI and config" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.claude-code;
          description = "Claude Code package to install.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;

        home.sessionVariables.CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude-code";

        home.file.".claude/CLAUDE.md".text = gitWorkflowInstructions;
        home.file.".claude/skills/git-workflow/SKILL.md".text = gitWorkflowSkill;
        home.file.".claude/commands/commit.md".text = commitCommand;
        home.file.".claude/commands/commit-push-pr.md".text = commitPushPrCommand;

        xdg.configFile."claude-code/README.md".text =
          "Claude Code config, skills, and command overrides are managed declaratively from the Nix home module.\n";

        xdg.configFile."claude-code/CLAUDE.md".text = gitWorkflowInstructions;
        xdg.configFile."claude-code/skills/git-workflow/SKILL.md".text = gitWorkflowSkill;
        xdg.configFile."claude-code/commands/commit.md".text = commitCommand;
        xdg.configFile."claude-code/commands/commit-push-pr.md".text = commitPushPrCommand;

        xdg.configFile."claude-code/settings.json".text = builtins.toJSON {
          "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        };
      };
    };
}
