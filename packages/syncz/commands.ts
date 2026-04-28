export type Command = {
  readonly description: string;
  readonly name: string;
  readonly run: (args: readonly string[], context: CommandContext) => CommandResult;
  readonly usage?: string;
};

export type CommandContext = {
  readonly help: () => string;
  readonly helpFor: (name: string) => string;
  readonly version: () => string;
};

export type CommandResult = {
  readonly code: number;
  readonly stderr?: string;
  readonly stdout?: string;
};

export const synczVersion = "0.1.0";

export const commands: readonly Command[] = [
  {
    description: "Print this help text.",
    name: "help",
    run: (args, context): CommandResult => ({
      code: 0,
      stdout: args[0] === undefined ? context.help() : context.helpFor(args[0]),
    }),
    usage: "[command]",
  },
  {
    description: "Print the syncz version.",
    name: "version",
    run: (args, context): CommandResult =>
      args.length === 0
        ? { code: 0, stdout: context.version() }
        : { code: 1, stderr: `version does not accept arguments: ${args.join(" ")}` },
  },
] as const;
