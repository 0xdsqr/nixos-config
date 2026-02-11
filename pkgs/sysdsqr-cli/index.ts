#!/usr/bin/env bun

import { cli, command, createHelpCommand } from "./cli.ts"

const init = command({
  description: "Initialize a new project from template",
  run: ({ args, ctx }) => {
    const template = args[0]

    if (!template) {
      console.log("Usage: sysdsqr init <template>")
      console.log("\nAvailable templates:")
      console.log("  basic        Basic NixOS configuration")
      console.log("  server       Server configuration")
      console.log("  desktop      Desktop configuration")
      process.exit(1)
    }

    console.log(`Initializing project with template: ${template}`)
    console.log(`Working directory: ${ctx.cwd}`)
  },
})

const commands = {
  init,
}

cli({
  ...commands,
  help: createHelpCommand(commands),
})
