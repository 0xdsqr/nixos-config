import type { Command, CommandContext, CommandResult } from "./commands.js";

export type CliIO = {
  argv: readonly string[];
  stderr: (value: string) => void;
  stdout: (value: string) => void;
};

export type CliResult = CommandResult;

export type CliConfig = {
  readonly commands: readonly Command[];
  readonly name: string;
  readonly version: string;
};

export type Cli = {
  readonly evaluate: (argv: readonly string[]) => CliResult;
  readonly run: (io: CliIO) => number;
};

type ParsedCli =
  | { kind: "command"; args: readonly string[]; name: string }
  | { kind: "help" }
  | { kind: "help-command"; name: string }
  | { kind: "version" };

const helpFlags = new Set(["--help", "-h"]);
const versionFlags = new Set(["--version", "-v"]);

export function createCli(config: CliConfig): Cli {
  const commandByName = new Map(config.commands.map((command) => [command.name, command]));
  const context: CommandContext = {
    help: () => renderHelp(config),
    helpFor: (name) => {
      const command = commandByName.get(name);

      return command === undefined ? `unknown command: ${name}\n\n${renderHelp(config)}` : renderCommandHelp(config, command);
    },
    version: () => versionText(config),
  };

  const evaluate = (argv: readonly string[]): CliResult => {
    const parsed = parseCli(argv);

    switch (parsed.kind) {
      case "help":
        return ok(renderHelp(config));

      case "help-command":
        return helpForCommand(config, commandByName, parsed.name);

      case "version":
        return ok(versionText(config));

      case "command": {
        const command = commandByName.get(parsed.name);

        if (command === undefined) {
          return fail(`unknown command: ${parsed.name}\n\n${renderHelp(config)}`);
        }

        if (parsed.args.some((arg) => helpFlags.has(arg))) {
          return ok(renderCommandHelp(config, command));
        }

        return command.run(parsed.args, context);
      }
    }
  };

  const run = (io: CliIO): number => {
    const result = evaluate(io.argv);

    if (result.stdout !== undefined) {
      io.stdout(ensureTrailingNewline(result.stdout));
    }

    if (result.stderr !== undefined) {
      io.stderr(ensureTrailingNewline(result.stderr));
    }

    return result.code;
  };

  return { evaluate, run };
}

function parseCli(argv: readonly string[]): ParsedCli {
  const [first = "help", ...rest] = argv;

  if (helpFlags.has(first)) {
    return { kind: "help" };
  }

  if (versionFlags.has(first)) {
    return { kind: "version" };
  }

  if (first === "help") {
    return rest[0] === undefined ? { kind: "help" } : { kind: "help-command", name: rest[0] };
  }

  return {
    kind: "command",
    args: rest,
    name: first,
  };
}

function ok(stdout: string): CliResult {
  return {
    code: 0,
    stdout,
  };
}

function fail(stderr: string, code = 1): CliResult {
  return {
    code,
    stderr,
  };
}

function helpForCommand(config: CliConfig, commandByName: ReadonlyMap<string, Command>, name: string): CliResult {
  const command = commandByName.get(name);

  if (command === undefined) {
    return fail(`unknown command: ${name}\n\n${renderHelp(config)}`);
  }

  return ok(renderCommandHelp(config, command));
}

function renderHelp(config: CliConfig): string {
  const rows = config.commands.map((command) => `  ${command.name.padEnd(12)} ${command.description}`);

  return [
    config.name,
    "",
    "usage:",
    `  ${config.name} <command> [args]`,
    "",
    "commands:",
    ...rows,
    "",
    "flags:",
    "  -h, --help     Print help.",
    "  -v, --version  Print version.",
  ].join("\n");
}

function renderCommandHelp(config: CliConfig, command: Command): string {
  return [
    `${config.name} ${command.name}`,
    "",
    command.description,
    "",
    "usage:",
    `  ${config.name} ${command.name}${command.usage === undefined ? "" : ` ${command.usage}`}`,
  ].join("\n");
}

function versionText(config: CliConfig): string {
  return `${config.name} ${config.version}`;
}

function ensureTrailingNewline(value: string): string {
  return value.endsWith("\n") ? value : `${value}\n`;
}
