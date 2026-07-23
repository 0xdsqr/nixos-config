import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const MAX_OUTPUT_BYTES = 50 * 1024;
const MAX_OUTPUT_LINES = 2_000;

export interface BoundedOutput {
  fullOutputPath?: string;
  text: string;
  truncated: boolean;
}

function truncateUtf8(value: string, maxBytes: number): string {
  if (Buffer.byteLength(value) <= maxBytes) return value;

  let low = 0;
  let high = value.length;
  while (low < high) {
    const middle = Math.ceil((low + high) / 2);
    if (Buffer.byteLength(value.slice(0, middle)) <= maxBytes) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return value.slice(0, low);
}

export function truncateOutput(value: string): { text: string; truncated: boolean } {
  const lines = value.split(/\r?\n/);
  let text = lines.length > MAX_OUTPUT_LINES ? lines.slice(0, MAX_OUTPUT_LINES).join("\n") : value;
  const lineTruncated = lines.length > MAX_OUTPUT_LINES;
  const byteTruncated = Buffer.byteLength(text) > MAX_OUTPUT_BYTES;
  if (byteTruncated) text = truncateUtf8(text, MAX_OUTPUT_BYTES);
  return { text: text.trimEnd(), truncated: lineTruncated || byteTruncated };
}

export async function boundOutput(value: string, prefix: string): Promise<BoundedOutput> {
  const bounded = truncateOutput(value);
  if (!bounded.truncated) return bounded;

  const directory = await mkdtemp(join(tmpdir(), `pi-${prefix}-`));
  const fullOutputPath = join(directory, "output.txt");
  await writeFile(fullOutputPath, value, "utf8");

  return {
    fullOutputPath,
    truncated: true,
    text: `${bounded.text}\n\n[Output truncated. Full output: ${fullOutputPath}]`,
  };
}
