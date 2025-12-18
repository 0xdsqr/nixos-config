type CliContext = {
  cwd: string
  env: Record<string, string | undefined>
}

type CommandInput<
  TFlags = Record<string, never>,
  TArgs extends Array<string> = Array<string>,
> = {
  flags: TFlags
  args: TArgs
  ctx: CliContext
}

type CommandSpec<
  TFlags = Record<string, never>,
  TArgs extends Array<string> = Array<string>,
> = {
  description?: string
  commands?: CommandMap
  parseFlags?: (args: Array<string>) => {
    flags: TFlags
    args: TArgs
  }
  preFlight?: (ctx: CliContext) => void | Promise<void>
  postFlight?: (ctx: CliContext) => void | Promise<void>
  run: (input: CommandInput<TFlags, TArgs>) => void | Promise<void>
}

type CommandMap = Record<string, CommandSpec>

type CliOptions = {
  preFlight?: (ctx: CliContext) => void | Promise<void>
  postFlight?: (ctx: CliContext) => void | Promise<void>
}

type ParsedCommand = {
  path: Array<string>
  rawArgs: Array<string>
}

const groupCommands = (
  argv: Array<string>,
  commands: CommandMap,
): Array<ParsedCommand> => {
  const { result, current } = argv.reduce<{
    result: Array<ParsedCommand>
    current: ParsedCommand | null
  }>(
    ({ result, current }, token) => {
      if (token in commands) {
        return {
          result: current ? [...result, current] : result,
          current: { path: [token], rawArgs: [] },
        }
      }
      if (!current) {
        throw new Error(`Unexpected arg before command: ${token}`)
      }
      return {
        result,
        current: { ...current, rawArgs: [...current.rawArgs, token] },
      }
    },
    { result: [], current: null },
  )
  return current ? [...result, current] : result
}

const resolveCommand = (
  path: Array<string>,
  commands: CommandMap,
): { spec: CommandSpec; args: Array<string> } | null => {
  const [first, ...rest] = path
  if (!first || !(first in commands)) return null

  const spec = commands[first]
  if (!spec) return null

  if (rest.length === 0) {
    return { spec, args: [] }
  }

  if (spec.commands && rest[0] && rest[0] in spec.commands) {
    const subResult = resolveCommand(rest, spec.commands)
    return subResult
  }

  return { spec, args: rest }
}

const createHelpCommand = (commands: CommandMap): CommandSpec => ({
  description: "Show available commands",
  run: () => {
    console.log("Available commands:\n")
    Object.entries(commands).forEach(([name, cmd]) => {
      console.log(`  ${name.padEnd(12)} ${cmd.description ?? ""}`)
    })
  },
})

const parseFlags = <TFlags extends Record<string, string | boolean>>(
  args: Array<string>,
): { flags: TFlags; args: Array<string> } => {
  const { flags, args: positionals } = args.reduce<{
    flags: Record<string, string | boolean>
    args: Array<string>
    skip: boolean
  }>(
    (acc, arg, i) => {
      if (acc.skip) return { ...acc, skip: false }
      if (arg.startsWith("--")) {
        const key = arg.slice(2)
        const next = args[i + 1]
        if (next && !next.startsWith("-")) {
          return { ...acc, flags: { ...acc.flags, [key]: next }, skip: true }
        }
        return { ...acc, flags: { ...acc.flags, [key]: true } }
      }
      return { ...acc, args: [...acc.args, arg] }
    },
    { flags: {}, args: [], skip: false },
  )
  return { flags: flags as TFlags, args: positionals }
}

const defineCli = (commands: CommandMap, options: CliOptions = {}) => {
  const ctx: CliContext = {
    cwd: process.cwd(),
    env: process.env,
  }

  const run = async (argv: Array<string>) => {
    if (argv.length === 0 || argv.includes("--help")) {
      createHelpCommand(commands).run({ flags: {}, args: [], ctx })
      return
    }

    const grouped = groupCommands(argv, commands)

    await Promise.all(
      grouped.map(async ({ path, rawArgs }) => {
        const resolved = resolveCommand(path, commands)
        if (!resolved) {
          throw new Error(`Unknown command: ${path.join(" ")}`)
        }

        const { spec, args: subArgs } = resolved
        const allArgs = [...subArgs, ...rawArgs]

        const parsed = spec.parseFlags
          ? spec.parseFlags(allArgs)
          : { flags: {}, args: allArgs }

        if (options.preFlight) {
          await options.preFlight(ctx)
        }

        if (spec.preFlight) {
          await spec.preFlight(ctx)
        }

        await spec.run({ ...parsed, ctx })

        if (spec.postFlight) {
          await spec.postFlight(ctx)
        }

        if (options.postFlight) {
          await options.postFlight(ctx)
        }
      }),
    )
  }

  return { run }
}

const command = <
  TFlags = Record<string, never>,
  TArgs extends Array<string> = Array<string>,
>(
  spec: CommandSpec<TFlags, TArgs>,
): CommandSpec<TFlags, TArgs> => spec

const subCommands = (commands: CommandMap): CommandMap => commands

const cli = (commands: CommandMap, options: CliOptions = {}) => {
  const instance = defineCli(commands, options)
  instance.run(process.argv.slice(2))
}

export type { CliContext, CommandInput, CommandSpec, CommandMap, CliOptions }
export { parseFlags, defineCli, createHelpCommand, command, subCommands, cli }
