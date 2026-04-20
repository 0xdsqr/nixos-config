# Tools

This workspace is managed by Nix.

The base host is Linux and headless.
That means terminal-first tools are the default shape of work here.

Current intent:
- use the built-in OpenClaw Linux toolchain
- enable `summarize` first
- keep macOS-only capabilities off this host
- add a macOS bridge later only if we actually need GUI or desktop-app actions

Nix will append an automatically generated tool and plugin report below this file.
