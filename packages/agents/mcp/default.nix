# MCP servers every agent host gets by default. Each entry is either a remote
# server (`url`, optional `headers`) or a local stdio server (`command`, `args`,
# `env`). Hosts can disable or retarget one through
# `dsqr.home.agentMcp.servers.<name>`, or add their own there.
{
  # Rex docs, changelog, and Rex Beta Discord history. Gated behind Discord
  # OAuth (Rex Beta members only); sign in once per agent. Named `superlogical`
  # rather than `rex` so it doesn't collide with Rex skills, instructions, or
  # the CLI. https://www.superlogical.com/rex/docs/beta/community-mcp
  superlogical.url = "https://www.superlogical.com/rex/community-mcp";
}
