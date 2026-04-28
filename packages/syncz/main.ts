import { createCli } from "./cli.js";
import { commands, synczVersion } from "./commands.js";

declare const process: {
  argv: string[];
  exitCode?: number;
  stderr: { write(value: string): void };
  stdout: { write(value: string): void };
};

const syncz = createCli({
  commands,
  name: "syncz",
  version: synczVersion,
});

process.exitCode = syncz.run({
  argv: process.argv.slice(2),
  stderr: (value: string) => process.stderr.write(value),
  stdout: (value: string) => process.stdout.write(value),
});
