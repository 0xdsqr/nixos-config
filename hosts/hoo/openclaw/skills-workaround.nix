_:
{
  dsqr.home.imports = [
    (
      { lib, ... }:
      {
        home.activation = {
          # Temporary workaround: current OpenClaw rejects workspace skills that
          # resolve through symlinks into /nix/store ("symlink-escape"), so we
          # materialize each skill directory into a real in-workspace copy.
          openclaw-workspace-skill-copies = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            fix_skills() {
              local skills_root="$1"
              local skill_dir
              local tmp_dir
              local needs_copy

              [ -d "$skills_root" ] || return 0

              for skill_dir in "$skills_root"/*; do
                [ -e "$skill_dir" ] || continue
                needs_copy=0

                if [ -L "$skill_dir" ]; then
                  needs_copy=1
                elif find "$skill_dir" -type l -print -quit | grep -q .; then
                  needs_copy=1
                fi

                [ "$needs_copy" -eq 1 ] || continue

                tmp_dir="$(mktemp -d)"
                cp -R -L "$skill_dir"/. "$tmp_dir"/
                rm -rf "$skill_dir"
                mkdir -p "$skill_dir"
                cp -R "$tmp_dir"/. "$skill_dir"/
                chmod -R u+rw "$skill_dir" || true
                rm -rf "$tmp_dir"
              done
            }

            fix_skills "$HOME/.openclaw-hoo/workspace/skills"
            fix_skills "$HOME/.openclaw-vanilla/workspace/skills"
          '';
        };
      }
    )
  ];
}
