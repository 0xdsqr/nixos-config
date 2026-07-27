import { inspect } from "node:util";

const REDACTED = "<redacted>";
const values = new WeakMap<object, unknown>();
const SENSITIVE_QUERY_KEY =
  /^(?:access[_-]?token|api[_-]?key|auth|authorization|credential|key|password|secret|signature|sig|token)$/i;

export interface Redacted<T> {
  readonly valueType?: T;
  toJSON(): string;
  toString(): string;
}

const redactedPrototype: Redacted<unknown> & { [inspect.custom](): string } = {
  toJSON: () => REDACTED,
  toString: () => REDACTED,
  [inspect.custom]: () => REDACTED,
};

export function redact<T>(value: T): Redacted<T> {
  const wrapper = Object.create(redactedPrototype) as Redacted<T>;
  values.set(wrapper, value);
  return wrapper;
}

export function reveal<T>(value: Redacted<T>): T {
  if (!values.has(value)) throw new Error("Invalid redacted value");
  return values.get(value) as T;
}

export function redactUrlForDisplay(rawUrl: string): string {
  try {
    const url = new URL(rawUrl);
    if (url.username || url.password) {
      url.username = REDACTED;
      url.password = "";
    }
    for (const key of [...url.searchParams.keys()]) {
      if (SENSITIVE_QUERY_KEY.test(key)) url.searchParams.set(key, REDACTED);
    }
    return url.href.replaceAll(encodeURIComponent(REDACTED), REDACTED);
  } catch {
    return rawUrl.replace(/^([a-z][a-z0-9+.-]*:\/\/)[^/@\s]+@/i, `$1${REDACTED}@`);
  }
}

export function redactUrlsInText(value: string): string {
  return value.replace(/\bhttps?:\/\/[^\s<>"')\]]+/gi, (candidate) => {
    const punctuation = candidate.match(/[.,;:!?]+$/)?.[0] ?? "";
    const url = punctuation ? candidate.slice(0, -punctuation.length) : candidate;
    return `${redactUrlForDisplay(url)}${punctuation}`;
  });
}
