declare module "@earendil-works/pi-ai" {
  export function StringEnum(values: readonly string[], options?: Record<string, unknown>): any;
}

declare module "@earendil-works/pi-coding-agent" {
  type ToolContent =
    | { type: "text"; text: string }
    | { type: "image"; data: string; mimeType: string };

  interface ToolResult {
    content: ToolContent[];
    details: unknown;
  }

  interface ToolRenderContext {
    isError: boolean;
  }

  interface ToolDefinition {
    name: string;
    label: string;
    description: string;
    parameters: unknown;
    execute: (
      toolCallId: string,
      params: any,
      signal: AbortSignal | undefined,
      onUpdate: ((result: ToolResult) => void) | undefined,
    ) => Promise<ToolResult>;
    promptGuidelines?: string[];
    promptSnippet?: string;
    renderCall?: (args: any, theme: any, context: ToolRenderContext) => unknown;
    renderResult?: (
      result: ToolResult,
      options: { expanded: boolean; isPartial: boolean },
      theme: any,
      context: ToolRenderContext,
    ) => unknown;
  }

  export interface ExtensionAPI {
    registerTool(tool: ToolDefinition): void;
  }

  export function keyHint(keybinding: string, description: string): string;
}

declare module "@earendil-works/pi-tui" {
  export class Text {
    constructor(text?: string, paddingX?: number, paddingY?: number);
    render(width: number): string[];
  }
}

declare module "typebox" {
  export const Type: any;
}

declare module "html-to-text" {
  export function compile(options?: Record<string, unknown>): (html: string) => string;
  export function convert(html: string, options?: Record<string, unknown>): string;
}

declare module "turndown" {
  export type Plugin = (service: TurndownService) => void;

  export default class TurndownService {
    constructor(options?: Record<string, unknown>);
    turndown(html: string): string;
    use(plugin: Plugin | readonly Plugin[]): this;
  }
}

declare module "turndown-plugin-gfm" {
  import type TurndownService from "turndown";

  export function gfm(service: TurndownService): void;
}
