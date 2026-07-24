declare module "@earendil-works/pi-coding-agent" {
  interface ExtensionAPI {
    on(event: string, handler: (event: any, context: any) => unknown): void;
    registerCommand(
      name: string,
      options: {
        description: string;
        handler: (args: string, context: any) => Promise<void> | void;
      },
    ): void;
    sendUserMessage(content: string, options?: { deliverAs?: "steer" | "followUp" }): void;
  }

  export function getAgentDir(): string;
  export type { ExtensionAPI };
}
