import { lookup } from "node:dns/promises";
import { request as httpRequest } from "node:http";
import type { IncomingHttpHeaders, IncomingMessage } from "node:http";
import { request as httpsRequest } from "node:https";
import { BlockList, isIP } from "node:net";

const MAX_RESPONSE_BYTES = 5 * 1024 * 1024;
const MAX_REDIRECTS = 5;
const REDIRECT_STATUSES = new Set([301, 302, 303, 307, 308]);
const RASTER_IMAGES = new Set(["image/gif", "image/jpeg", "image/png", "image/webp"]);
const BLOCKED_IPS = new BlockList();

const BLOCKED_IPV4_SUBNETS = [
  ["0.0.0.0", 8],
  ["10.0.0.0", 8],
  ["100.64.0.0", 10],
  ["127.0.0.0", 8],
  ["169.254.0.0", 16],
  ["172.16.0.0", 12],
  ["192.0.0.0", 24],
  ["192.168.0.0", 16],
  ["198.18.0.0", 15],
  ["198.51.100.0", 24],
  ["203.0.113.0", 24],
  ["224.0.0.0", 3],
] as const;

for (const [address, prefix] of BLOCKED_IPV4_SUBNETS) {
  BLOCKED_IPS.addSubnet(address, prefix, "ipv4");
  BLOCKED_IPS.addSubnet(`::ffff:${address}`, 96 + prefix, "ipv6");
}

for (const [address, prefix] of [
  ["::", 96],
  ["64:ff9b::", 96],
  ["64:ff9b:1::", 48],
  ["100::", 64],
  ["2001::", 23],
  ["2001:db8::", 32],
  ["2002::", 16],
  ["3fff::", 20],
  ["fc00::", 7],
  ["fe80::", 10],
  ["ff00::", 8],
] as const) {
  BLOCKED_IPS.addSubnet(address, prefix, "ipv6");
}

export type FetchFormat = "html" | "markdown" | "text";

export type FetchedPage =
  | {
      kind: "image";
      bytes: number;
      data: string;
      finalUrl: string;
      mediaType: string;
    }
  | {
      kind: "text";
      bytes: number;
      contentType: string;
      finalUrl: string;
      text: string;
    };

interface PublicDestination {
  address: string;
  family: 4 | 6;
}

function stripIpv6Brackets(hostname: string): string {
  return hostname.replace(/^\[/, "").replace(/\]$/, "");
}

export function isBlockedIp(address: string): boolean {
  const normalized = stripIpv6Brackets(address);
  const version = isIP(normalized);
  return version === 4
    ? BLOCKED_IPS.check(normalized, "ipv4")
    : version === 6
      ? BLOCKED_IPS.check(normalized, "ipv6")
      : true;
}

export function parsePublicUrl(value: string, baseUrl?: string): URL {
  let url: URL;
  try {
    url = baseUrl ? new URL(value, baseUrl) : new URL(value);
  } catch {
    throw new Error("Invalid URL");
  }

  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error("URL must use http:// or https://");
  }
  if (url.username || url.password) {
    throw new Error("URLs containing credentials are not supported");
  }
  if (!url.hostname) {
    throw new Error("URL must include a hostname");
  }

  url.hash = "";
  return url;
}

export async function resolvePublicDestination(url: URL): Promise<PublicDestination> {
  const hostname = stripIpv6Brackets(url.hostname).toLowerCase();
  if (hostname === "localhost" || hostname.endsWith(".localhost")) {
    throw new Error("Private or local destinations are blocked");
  }

  const literalFamily = isIP(hostname);
  if (literalFamily) {
    if (isBlockedIp(hostname)) throw new Error("Private or local destinations are blocked");
    return { address: hostname, family: literalFamily };
  }

  let addresses: Awaited<ReturnType<typeof lookup>>;
  try {
    addresses = await lookup(hostname, { all: true, verbatim: true });
  } catch {
    throw new Error("Could not resolve URL hostname");
  }
  if (addresses.length === 0 || addresses.some(({ address }) => isBlockedIp(address))) {
    throw new Error("Private or local destinations are blocked");
  }

  const destination = addresses[0];
  if (!destination || (destination.family !== 4 && destination.family !== 6)) {
    throw new Error("Could not resolve URL hostname");
  }
  return destination;
}

function firstHeader(headers: IncomingHttpHeaders, name: string): string | undefined {
  const value = headers[name];
  return Array.isArray(value) ? value[0] : value;
}

function contentType(headers: IncomingHttpHeaders): { charset: string; mime: string } {
  const raw = firstHeader(headers, "content-type") ?? "application/octet-stream";
  const [mime = "application/octet-stream", ...parameters] = raw.split(";");
  const charset = parameters
    .map((parameter) => parameter.trim().match(/^charset=(.+)$/i)?.[1]?.replace(/^["']|["']$/g, ""))
    .find(Boolean) ?? "utf-8";
  return { charset, mime: mime.trim().toLowerCase() };
}

export async function readLimitedIncomingBody(
  response: IncomingMessage,
  limit = MAX_RESPONSE_BYTES,
): Promise<Uint8Array> {
  const declaredLength = Number.parseInt(firstHeader(response.headers, "content-length") ?? "", 10);
  if (Number.isFinite(declaredLength) && declaredLength > limit) {
    response.destroy();
    throw new Error(`Response exceeds the ${Math.floor(limit / 1024 / 1024)}MB limit`);
  }

  const chunks: Uint8Array[] = [];
  let total = 0;

  for await (const chunk of response) {
    const value = typeof chunk === "string" ? Buffer.from(chunk) : chunk;
    total += value.byteLength;
    if (total > limit) {
      response.destroy();
      throw new Error(`Response exceeds the ${Math.floor(limit / 1024 / 1024)}MB limit`);
    }
    chunks.push(value);
  }

  const body = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return body;
}

export async function readLimitedBody(response: Response, limit = MAX_RESPONSE_BYTES): Promise<Uint8Array> {
  const declaredLength = Number.parseInt(response.headers.get("content-length") ?? "", 10);
  if (Number.isFinite(declaredLength) && declaredLength > limit) {
    await response.body?.cancel();
    throw new Error(`Response exceeds the ${Math.floor(limit / 1024 / 1024)}MB limit`);
  }

  if (!response.body) return new Uint8Array();
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > limit) {
      await reader.cancel();
      throw new Error(`Response exceeds the ${Math.floor(limit / 1024 / 1024)}MB limit`);
    }
    chunks.push(value);
  }

  const body = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return body;
}

function decodeBody(body: Uint8Array, charset: string): string {
  try {
    return new TextDecoder(charset).decode(body);
  } catch {
    return new TextDecoder("utf-8").decode(body);
  }
}

function composeSignal(signal: AbortSignal | undefined, timeoutSeconds: number): {
  cleanup: () => void;
  signal: AbortSignal;
} {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(new Error("Request timed out")), timeoutSeconds * 1000);
  const abort = () => controller.abort(signal?.reason);
  signal?.addEventListener("abort", abort, { once: true });

  return {
    signal: controller.signal,
    cleanup: () => {
      clearTimeout(timer);
      signal?.removeEventListener("abort", abort);
    },
  };
}

function fetchPinned(
  url: URL,
  destination: PublicDestination,
  signal: AbortSignal,
): Promise<IncomingMessage> {
  const request = url.protocol === "https:" ? httpsRequest : httpRequest;

  return new Promise((resolve, reject) => {
    const outgoing = request(
      {
        family: destination.family,
        headers: {
          accept: "text/markdown, text/html;q=0.9, text/plain;q=0.8, image/*;q=0.7, */*;q=0.1",
          host: url.host,
          "user-agent": "pi-web-tools/0.1 (+https://pi.dev)",
        },
        hostname: destination.address,
        method: "GET",
        path: `${url.pathname}${url.search}`,
        port: url.port || undefined,
        servername: isIP(stripIpv6Brackets(url.hostname)) ? undefined : url.hostname,
        signal,
      },
      resolve,
    );
    outgoing.once("error", reject);
    outgoing.end();
  });
}

export async function fetchPublicPage(
  rawUrl: string,
  timeoutSeconds: number,
  signal?: AbortSignal,
): Promise<FetchedPage> {
  const operation = composeSignal(signal, timeoutSeconds);
  let url = parsePublicUrl(rawUrl);

  try {
    for (let redirects = 0; redirects <= MAX_REDIRECTS; redirects += 1) {
      const destination = await resolvePublicDestination(url);

      let response: IncomingMessage;
      try {
        response = await fetchPinned(url, destination, operation.signal);
      } catch (error) {
        if (operation.signal.aborted) {
          throw new Error(signal?.aborted ? "Web fetch cancelled" : `Web fetch timed out after ${timeoutSeconds}s`);
        }
        throw new Error(`Web fetch failed: ${error instanceof Error ? error.message : "unknown error"}`);
      }

      const status = response.statusCode ?? 0;
      if (REDIRECT_STATUSES.has(status)) {
        if (redirects === MAX_REDIRECTS) {
          response.destroy();
          throw new Error(`Web fetch exceeded ${MAX_REDIRECTS} redirects`);
        }
        const location = firstHeader(response.headers, "location");
        response.destroy();
        if (!location) throw new Error("Redirect response did not include a destination");
        url = parsePublicUrl(location, url.href);
        continue;
      }

      if (status < 200 || status >= 300) {
        response.destroy();
        throw new Error(`Web fetch failed with HTTP ${status}`);
      }

      const type = contentType(response.headers);
      const body = await readLimitedIncomingBody(response);
      if (RASTER_IMAGES.has(type.mime)) {
        return {
          kind: "image",
          bytes: body.byteLength,
          data: Buffer.from(body).toString("base64"),
          finalUrl: url.href,
          mediaType: type.mime,
        };
      }

      const isText = type.mime.startsWith("text/")
        || type.mime === "application/json"
        || type.mime === "application/xhtml+xml"
        || type.mime === "application/xml"
        || type.mime === "image/svg+xml";
      if (!isText) {
        throw new Error(`Unsupported response type: ${type.mime}`);
      }

      return {
        kind: "text",
        bytes: body.byteLength,
        contentType: type.mime,
        finalUrl: url.href,
        text: decodeBody(body, type.charset),
      };
    }
  } finally {
    operation.cleanup();
  }

  throw new Error("Web fetch failed");
}
