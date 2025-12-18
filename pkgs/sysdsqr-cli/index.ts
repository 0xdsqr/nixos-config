#!/usr/bin/env bun

const args = process.argv.slice(2);
const command = args[0];

process.argv.forEach((arg) => {
    console.log("found arg", arg);
});
if (!command) {
    console.log("hello world");
} else if (command === "hello") {
    console.log("world");
} else {
    console.log(`Unknown command: ${command}`);
    process.exit(1);
}
