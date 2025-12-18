# sysdsqr

Type-safe, functional CLI framework for building command-line tools.

## Features

- **Fully Type-Safe**: Generic types with proper inference
- **Functional Style**: Composable command helpers
- **Sub-commands**: Unlimited nesting (e.g., `git remote add`)
- **Pre/Post-flight**: Global and per-command lifecycle hooks
- **Command Chaining**: Run multiple commands in one invocation
- **Auto Help**: Generated help from command descriptions
- **Flag Parsing**: Type-safe flag and argument parsing

## Quick Start

```typescript
#!/usr/bin/env bun
import { cli, command } from "./cli.ts";

const hello = command({
  description: "Say hello",
  run: () => console.log("world"),
});

cli({ hello });
```

```bash
$ sysdsqr hello
world
```

## Usage

### Basic Command

Define isolated commands using the `command()` helper:

```typescript
import { cli, command } from "./cli.ts";

const greet = command({
  description: "Greet someone",
  run: ({ args }) => {
    const name = args[0] || "world";
    console.log(`Hello, ${name}!`);
  },
});

cli({ greet });
```

```bash
$ sysdsqr greet Alice
Hello, Alice!
```

### Sub-commands

Create nested command structures with `subCommands()`:

```typescript
import { cli, command, subCommands } from "./cli.ts";

const remoteAdd = command({
  description: "Add a remote",
  run: ({ args }) => {
    const [name, url] = args;
    console.log(`Adding remote ${name}: ${url}`);
  },
});

const remoteList = command({
  description: "List remotes",
  run: () => {
    console.log("origin\tupstream");
  },
});

const remote = command({
  description: "Manage remotes",
  commands: subCommands({
    add: remoteAdd,
    list: remoteList,
  }),
  run: () => console.log("Use: git remote <add|list>"),
});

const git = command({
  description: "Git operations",
  commands: subCommands({
    remote,
  }),
  run: () => console.log("Use: git <remote>"),
});

cli({ git });
```

```bash
$ sysdsqr git remote add origin https://github.com/user/repo
Adding remote origin: https://github.com/user/repo

$ sysdsqr git remote list
origin  upstream
```

### Pre-flight & Post-flight

Add lifecycle hooks for setup and cleanup:

```typescript
const deploy = command({
  description: "Deploy application",
  preFlight: async (ctx) => {
    console.log("Validating environment...");
    console.log(`Working directory: ${ctx.cwd}`);
  },
  run: async () => {
    console.log("Deploying...");
    await deploy();
  },
  postFlight: async () => {
    console.log("Cleaning up temp files...");
  },
});

cli({ deploy });
```

**Execution order:**
1. Global `preFlight` (if defined)
2. Command `preFlight` (if defined)
3. Command `run`
4. Command `postFlight` (if defined)
5. Global `postFlight` (if defined)

### Global Lifecycle Hooks

Run hooks before/after every command:

```typescript
cli(
  { build, test, deploy },
  {
    preFlight: async (ctx) => {
      console.log("Checking environment...");
      if (!ctx.env.API_KEY) {
        throw new Error("API_KEY not set");
      }
    },
    postFlight: async () => {
      console.log("All done!");
    },
  }
);
```

### Flags and Arguments

Parse flags with type safety:

```typescript
import { cli, command, parseFlags } from "./cli.ts";

type BuildFlags = {
  watch: boolean;
  output: string;
  minify: boolean;
};

const build = command({
  description: "Build the project",
  parseFlags: (args) => parseFlags<BuildFlags>(args),
  run: ({ flags, args }) => {
    console.log("Flags:", flags);
    console.log("Files:", args);
  },
});

cli({ build });
```

```bash
$ sysdsqr build --watch --output dist --minify src/index.ts src/app.ts
Flags: { watch: true, output: "dist", minify: true }
Files: ["src/index.ts", "src/app.ts"]
```

### Context Access

Every command receives a `ctx` object with environment info:

```typescript
const debug = command({
  description: "Debug info",
  run: ({ ctx }) => {
    console.log(`CWD: ${ctx.cwd}`);
    console.log(`USER: ${ctx.env.USER}`);
    console.log(`PATH: ${ctx.env.PATH}`);
  },
});
```

### Command Chaining

Execute multiple commands in sequence:

```bash
$ sysdsqr clean build test deploy
```

Each command runs with its own pre/post-flight hooks.

### Help Command

Auto-generate help from descriptions:

```typescript
import { cli, command, createHelpCommand } from "./cli.ts";

const commands = {
  build: command({ description: "Build project", run: () => {} }),
  test: command({ description: "Run tests", run: () => {} }),
};

cli({
  ...commands,
  help: createHelpCommand(commands),
});
```

```bash
$ sysdsqr help
Available commands:

  build        Build project
  test         Run tests
  help         Show available commands

$ sysdsqr --help
# same output
```

## API Reference

<details>
<summary><strong>Types</strong></summary>

### `CliContext`

Context passed to all commands and hooks:

```typescript
type CliContext = {
  cwd: string;
  env: Record<string, string | undefined>;
};
```

### `CommandInput<TFlags, TArgs>`

Input passed to command `run` function:

```typescript
type CommandInput<TFlags, TArgs> = {
  flags: TFlags;
  args: TArgs;
  ctx: CliContext;
};
```

### `CommandSpec<TFlags, TArgs>`

Command specification:

```typescript
type CommandSpec<TFlags, TArgs> = {
  description?: string;
  commands?: CommandMap;
  parseFlags?: (args: Array<string>) => { flags: TFlags; args: TArgs };
  preFlight?: (ctx: CliContext) => void | Promise<void>;
  postFlight?: (ctx: CliContext) => void | Promise<void>;
  run: (input: CommandInput<TFlags, TArgs>) => void | Promise<void>;
};
```

### `CommandMap`

Map of command names to specs:

```typescript
type CommandMap = Record<string, CommandSpec>;
```

### `CliOptions`

Options for CLI initialization:

```typescript
type CliOptions = {
  preFlight?: (ctx: CliContext) => void | Promise<void>;
  postFlight?: (ctx: CliContext) => void | Promise<void>;
};
```

</details>

<details>
<summary><strong>Functions</strong></summary>

### `command<TFlags, TArgs>(spec: CommandSpec<TFlags, TArgs>): CommandSpec<TFlags, TArgs>`

Helper to define a command with type safety:

```typescript
const myCommand = command({
  description: "My command",
  run: () => console.log("Hello"),
});
```

**Type Parameters:**
- `TFlags`: Type of parsed flags (default: `Record<string, never>`)
- `TArgs`: Type of positional args (default: `Array<string>`)

**Properties:**
- `description?`: Short description for help text
- `commands?`: Nested sub-commands
- `parseFlags?`: Custom flag parser
- `preFlight?`: Hook before run
- `postFlight?`: Hook after run
- `run`: Main command logic

### `subCommands(commands: CommandMap): CommandMap`

Helper to define sub-commands with type safety:

```typescript
const git = command({
  commands: subCommands({
    status: command({ run: () => {} }),
    commit: command({ run: () => {} }),
  }),
  run: () => {},
});
```

### `cli(commands: CommandMap, options?: CliOptions): void`

Initialize and run the CLI (handles `process.argv` automatically):

```typescript
cli(
  { build, test, deploy },
  {
    preFlight: async () => console.log("Starting..."),
    postFlight: async () => console.log("Done!"),
  }
);
```

**Parameters:**
- `commands`: Map of top-level commands
- `options?`: Optional global pre/post-flight hooks

**Note:** Automatically processes `process.argv.slice(2)` - no need to call `.run()`

### `parseFlags<TFlags>(args: Array<string>): { flags: TFlags; args: Array<string> }`

Parse command-line flags and positional arguments:

```typescript
const { flags, args } = parseFlags<{ watch: boolean; output: string }>(
  ["--watch", "--output", "dist", "file.ts"]
);
// flags: { watch: true, output: "dist" }
// args: ["file.ts"]
```

**Format:**
- `--flag value` → `{ flag: "value" }`
- `--flag` → `{ flag: true }`
- Other tokens → positional args

### `createHelpCommand(commands: CommandMap): CommandSpec`

Factory to generate a help command:

```typescript
const help = createHelpCommand(commands);
cli({ ...commands, help });
```

### `defineCli(commands: CommandMap, options?: CliOptions): { run: (argv: Array<string>) => Promise<void> }`

Low-level CLI builder (use `cli()` instead for automatic argv handling):

```typescript
const cliInstance = defineCli(commands);
await cliInstance.run(["build", "--watch"]);
```

</details>

<details>
<summary><strong>Advanced Patterns</strong></summary>

### Conditional Commands

```typescript
const devCommands = process.env.NODE_ENV === "development"
  ? { debug: command({ run: () => {} }) }
  : {};

cli({ build, test, ...devCommands });
```

### Shared Logic

```typescript
const withAuth = (cmd: CommandSpec): CommandSpec => ({
  ...cmd,
  preFlight: async (ctx) => {
    if (!ctx.env.TOKEN) throw new Error("Not authenticated");
    if (cmd.preFlight) await cmd.preFlight(ctx);
  },
});

const deploy = withAuth(command({ run: () => {} }));
```

### Command Composition

```typescript
const baseCommand = {
  preFlight: async () => console.log("Setup"),
  postFlight: async () => console.log("Cleanup"),
};

const build = command({
  ...baseCommand,
  description: "Build project",
  run: () => console.log("Building..."),
});
```

</details>

## Testing

### Local Testing with Bun

```bash
cd pkgs/sysdsqr-cli

# Run directly
bun run index.ts hello
bun run index.ts git remote add origin url

# Build executable
bun run build
./sysdsqr hello
```

### Testing with Nix

```bash
# Build the package
nix build .#sysdsqr-cli

# Run with arguments
./result/bin/sysdsqr hello
./result/bin/sysdsqr git remote add origin https://github.com/user/repo
./result/bin/sysdsqr --help

# Or use nix run
nix run .#sysdsqr-cli -- hello
nix run .#sysdsqr-cli -- git status
```

### Development Mode

```bash
# Watch mode for development
bun --watch index.ts hello
```

## Examples

See `index.ts` for a complete example with:
- Multiple isolated commands
- Nested sub-commands (3 levels deep)
- Per-command pre/post-flight hooks
- Global lifecycle hooks
- Type-safe flag parsing

## Building

```bash
bun run build
```

Outputs a standalone executable at `./sysdsqr`.

## License

MIT
