import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, isAbsolute, join, resolve } from "node:path";

export type CloakMode = "all" | "assignments" | "detect";

export interface CloakRuleConfig {
  files: string[];
  mode: CloakMode;
}

export interface CloakPatternConfig {
  flags?: string;
  pattern: string;
}

export interface CloakConfig {
  enabled: boolean;
  includeDefaultRules: boolean;
  mask: string;
  patterns: CloakPatternConfig[];
  rules: CloakRuleConfig[];
}

interface CompiledRule {
  matchers: RegExp[];
  mode: CloakMode;
}

interface CompiledPattern {
  regex: RegExp;
}

export interface CloakState {
  config: CloakConfig;
  configPath: string;
  errors: string[];
  patterns: CompiledPattern[];
  rules: CompiledRule[];
}

export interface CloakResult {
  replacements: number;
  text: string;
}

const DEFAULT_RULES: CloakRuleConfig[] = [
  {
    files: [
      "**/.env",
      "**/.env.*",
      "**/.envrc",
      "**/.envrc.*",
      "**/.direnv/**",
      "**/local.nix",
      "**/*.local.nix",
      "**/*secret*.nix",
    ],
    mode: "assignments",
  },
  {
    files: [
      "**/*.age",
      "**/*.key",
      "**/*.p12",
      "**/*.pfx",
      "**/*.pem",
      "**/credentials",
      "**/credentials.*",
      "**/id_ed25519",
      "**/id_rsa",
      "**/secrets.json",
      "**/secrets.yaml",
      "**/secrets.yml",
    ],
    mode: "all",
  },
];

const DEFAULT_CONFIG: CloakConfig = {
  enabled: true,
  includeDefaultRules: true,
  mask: "[REDACTED]",
  patterns: [],
  rules: [],
};

const SENSITIVE_NAME =
  String.raw`(?:api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|private[_-]?key|secret[_-]?key|password|passwd|passphrase|credential|credentials|token|secret)`;

const BUILTIN_PATTERNS = [
  /-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z0-9 ]*PRIVATE KEY-----/g,
  /\bAGE-SECRET-KEY-1[0-9A-Z]+\b/gi,
  /\b(?:github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9_]{20,})\b/g,
  /\bsk-(?:ant-|proj-|svcacct-)?[A-Za-z0-9_-]{16,}\b/g,
  /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/g,
  /\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b/g,
];

const SENSITIVE_ASSIGNMENT = new RegExp(
  String.raw`(\b${SENSITIVE_NAME}\b\s*(?:=|:)\s*)(?:"[^"\n]*"|'[^'\n]*'|[^\s,;}\]]+)`,
  "gi",
);
const AUTHORIZATION_VALUE =
  /(\b(?:authorization|proxy-authorization)\b\s*[:=]\s*(?:(?:bearer|basic)\s+)?)([^\s,;]+)/gi;
const CREDENTIAL_URL = /(https?:\/\/[^/\s:@]+:)([^@\s/]+)(@)/gi;
const SECRET_QUERY =
  /([?&](?:api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|password|token|secret)=)([^&#\s]*)/gi;
const ENV_ASSIGNMENT =
  /^((?:.+?(?::\d+:|-\d+-)\s)?\s*(?:export\s+)?[A-Za-z_][A-Za-z0-9_]*\s*=\s*)(.*)$/gm;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function normalizePath(value: string): string {
  let result = value.trim().replace(/^@/, "");
  if (result === "~") result = homedir();
  else if (result.startsWith("~/")) result = join(homedir(), result.slice(2));
  return result.replaceAll("\\", "/");
}

function escapeRegex(value: string): string {
  return value.replace(/[|\\{}()[\]^$+?.]/g, "\\$&");
}

export function globToRegExp(glob: string): RegExp {
  const normalized = normalizePath(glob);
  let pattern = "^";
  for (let index = 0; index < normalized.length; index += 1) {
    const character = normalized[index]!;
    const next = normalized[index + 1];
    const afterNext = normalized[index + 2];
    if (character === "*" && next === "*") {
      if (afterNext === "/") {
        pattern += "(?:.*/)?";
        index += 2;
      } else {
        pattern += ".*";
        index += 1;
      }
    } else if (character === "*") {
      pattern += "[^/]*";
    } else if (character === "?") {
      pattern += "[^/]";
    } else {
      pattern += escapeRegex(character);
    }
  }
  return new RegExp(`${pattern}$`);
}

function parseRule(value: unknown, index: number, errors: string[]): CloakRuleConfig | undefined {
  if (!isRecord(value)) {
    errors.push(`rules[${index}] must be an object`);
    return undefined;
  }
  const files = Array.isArray(value.files)
    ? value.files.filter((item): item is string => typeof item === "string" && item.trim().length > 0)
    : [];
  const mode = value.mode;
  if (files.length === 0 || (mode !== "all" && mode !== "assignments" && mode !== "detect")) {
    errors.push(`rules[${index}] requires non-empty files and mode all, assignments, or detect`);
    return undefined;
  }
  return { files, mode };
}

function normalizeFlags(value: unknown, index: number, errors: string[]): string | undefined {
  if (value === undefined) return "g";
  if (typeof value !== "string" || /[^imsuy]/.test(value)) {
    errors.push(`patterns[${index}].flags contains unsupported flags`);
    return undefined;
  }
  return Array.from(new Set(`${value}g`)).join("");
}

function parsePattern(value: unknown, index: number, errors: string[]): CloakPatternConfig | undefined {
  if (!isRecord(value) || typeof value.pattern !== "string" || value.pattern.length === 0) {
    errors.push(`patterns[${index}] requires a non-empty pattern`);
    return undefined;
  }
  if (value.pattern.length > 2_048) {
    errors.push(`patterns[${index}] exceeds the 2048-character limit`);
    return undefined;
  }
  const flags = normalizeFlags(value.flags, index, errors);
  return flags ? { pattern: value.pattern, flags } : undefined;
}

export function parseCloakConfig(value: unknown, configPath = "<memory>"): CloakState {
  const errors: string[] = [];
  const record = isRecord(value) ? value : {};
  if (!isRecord(value)) errors.push("config root must be an object");

  const enabled = typeof record.enabled === "boolean" ? record.enabled : DEFAULT_CONFIG.enabled;
  const includeDefaultRules = typeof record.includeDefaultRules === "boolean"
    ? record.includeDefaultRules
    : DEFAULT_CONFIG.includeDefaultRules;
  const mask = typeof record.mask === "string" && record.mask.length > 0 && record.mask.length <= 128
    ? record.mask
    : DEFAULT_CONFIG.mask;
  if (record.mask !== undefined && mask !== record.mask) {
    errors.push("mask must contain between 1 and 128 characters");
  }

  const customRules = Array.isArray(record.rules)
    ? record.rules.flatMap((rule, index) => {
        const parsed = parseRule(rule, index, errors);
        return parsed ? [parsed] : [];
      })
    : [];
  if (record.rules !== undefined && !Array.isArray(record.rules)) errors.push("rules must be an array");

  const patterns = Array.isArray(record.patterns)
    ? record.patterns.flatMap((pattern, index) => {
        const parsed = parsePattern(pattern, index, errors);
        return parsed ? [parsed] : [];
      })
    : [];
  if (record.patterns !== undefined && !Array.isArray(record.patterns)) errors.push("patterns must be an array");

  const rules = [...(includeDefaultRules ? DEFAULT_RULES : []), ...customRules];
  const compiledPatterns = patterns.flatMap((pattern, index) => {
    try {
      return [{ regex: new RegExp(pattern.pattern, pattern.flags) }];
    } catch {
      errors.push(`patterns[${index}] is not a valid regular expression`);
      return [];
    }
  });

  return {
    config: { enabled, includeDefaultRules, mask, patterns, rules: customRules },
    configPath,
    errors,
    patterns: compiledPatterns,
    rules: rules.map((rule) => ({
      matchers: rule.files.map(globToRegExp),
      mode: rule.mode,
    })),
  };
}

export function loadCloakState(configPath: string): CloakState {
  if (!existsSync(configPath)) return parseCloakConfig(DEFAULT_CONFIG, configPath);
  try {
    return parseCloakConfig(JSON.parse(readFileSync(configPath, "utf8")), configPath);
  } catch (error) {
    const state = parseCloakConfig(DEFAULT_CONFIG, configPath);
    state.errors.push(`failed to load config: ${error instanceof Error ? error.message : String(error)}`);
    return state;
  }
}

function pathCandidates(rawPath: string, cwd: string): string[] {
  const normalized = normalizePath(rawPath);
  const absolute = normalizePath(isAbsolute(normalized) ? normalized : resolve(cwd, normalized));
  return Array.from(new Set([normalized, absolute, basename(normalized), basename(absolute)]));
}

function modeForPaths(paths: string[], cwd: string, state: CloakState): CloakMode {
  let selected: CloakMode = "detect";
  for (const rule of state.rules) {
    const matched = paths.some((path) =>
      pathCandidates(path, cwd).some((candidate) => rule.matchers.some((matcher) => matcher.test(candidate)))
    );
    if (!matched) continue;
    if (rule.mode === "all") return "all";
    if (rule.mode === "assignments") selected = "assignments";
  }
  return selected;
}

function replaceWithMask(
  text: string,
  regex: RegExp,
  replacement: (...groups: string[]) => string,
): CloakResult {
  let replacements = 0;
  const updated = text.replace(regex, (...args: unknown[]) => {
    replacements += 1;
    const groups = args.slice(0, Math.max(0, args.length - 2)).map((value) => String(value ?? ""));
    return replacement(...groups);
  });
  return { text: updated, replacements };
}

function combine(current: CloakResult, next: CloakResult): CloakResult {
  return {
    text: next.text,
    replacements: current.replacements + next.replacements,
  };
}

function applyDetectedPatterns(text: string, state: CloakState): CloakResult {
  let result: CloakResult = { text, replacements: 0 };
  result = combine(
    result,
    replaceWithMask(result.text, SENSITIVE_ASSIGNMENT, (_match, prefix) => `${prefix}${state.config.mask}`),
  );
  result = combine(
    result,
    replaceWithMask(result.text, AUTHORIZATION_VALUE, (_match, prefix) => `${prefix}${state.config.mask}`),
  );
  result = combine(
    result,
    replaceWithMask(result.text, CREDENTIAL_URL, (_match, prefix, _secret, suffix) =>
      `${prefix}${state.config.mask}${suffix}`
    ),
  );
  result = combine(
    result,
    replaceWithMask(result.text, SECRET_QUERY, (_match, prefix) => `${prefix}${state.config.mask}`),
  );
  for (const pattern of BUILTIN_PATTERNS) {
    result = combine(result, replaceWithMask(result.text, pattern, () => state.config.mask));
  }
  for (const pattern of state.patterns) {
    result = combine(result, replaceWithMask(result.text, pattern.regex, () => state.config.mask));
  }
  return result;
}

export function cloakText(text: string, paths: string[], cwd: string, state: CloakState): CloakResult {
  if (!state.config.enabled || text.length === 0) return { text, replacements: 0 };

  const mode = modeForPaths(paths, cwd, state);
  if (mode === "all") {
    return { text: `${state.config.mask} sensitive file contents`, replacements: 1 };
  }

  let result = applyDetectedPatterns(text, state);
  if (mode === "assignments") {
    result = combine(
      result,
      replaceWithMask(result.text, ENV_ASSIGNMENT, (match, prefix, value) => {
        if (!value.trim() || value.trim().startsWith("#")) return match;
        return `${prefix}${state.config.mask}`;
      }),
    );
  }
  return result;
}

function addCommandPathCandidates(paths: Set<string>, command: string): void {
  for (const token of command.match(/[^\s"'`;|&<>]+/g) ?? []) {
    const cleaned = token.replace(/^[()[\]{}]+|[()[\]{},]+$/g, "");
    if (cleaned) paths.add(cleaned);
  }
}

function addGrepOutputPaths(paths: Set<string>, text: string, root: string): void {
  for (const line of text.split(/\r?\n/)) {
    const match = line.match(/^(.+?)(?::\d+:|-\d+-)\s/);
    if (match?.[1]) paths.add(join(root, match[1]));
  }
}

export function toolResultPaths(
  toolName: string,
  input: Record<string, unknown>,
  cwd: string,
  text = "",
): string[] {
  const paths = new Set<string>();
  for (const key of ["path", "file", "filePath", "file_path", "filename"]) {
    const value = input[key];
    if (typeof value === "string" && value.trim()) paths.add(value);
  }
  if (toolName === "grep" && typeof input.glob === "string") {
    const root = typeof input.path === "string" ? input.path : cwd;
    paths.add(join(root, input.glob));
  }
  if (toolName === "grep" && text) {
    addGrepOutputPaths(paths, text, typeof input.path === "string" ? input.path : cwd);
  }
  if (toolName === "bash" && typeof input.command === "string") {
    addCommandPathCandidates(paths, input.command);
  }
  return Array.from(paths);
}
