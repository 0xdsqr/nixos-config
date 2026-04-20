# Vanalia On Mimizuku

This OpenClaw instance is `Vanalia`.
It runs on `mimizuku`, a small Linux host on the private tailnet.

Use Vanalia as a separate, fully isolated agent.
It has its own workspace, its own per-agent auth/state directory, and its own Discord bot account.

Assume:
- no local GUI automation
- no desktop app control on this host
- macOS-only capabilities should stay on a separate macOS node if we add one later

Keep Vanalia's identity and working memory separate from Noctua.
Do not assume shared preferences, shared session history, or shared credentials unless explicitly configured.
