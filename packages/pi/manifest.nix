{
  pi = {
    browser-tools = {
      kind = "npm";
      description = "Pi skill: Chrome DevTools browser automation";
    };
    brave-search = {
      kind = "npm";
      description = "Pi skill: Brave Search API lookup and content extraction";
    };
    transcribe = {
      kind = "static";
      description = "Pi skill: Groq Whisper speech-to-text transcription";
    };
    vscode = {
      kind = "static";
      description = "Pi skill: VS Code integration for diffs and file comparison";
    };
  };

  anthropic = {
    algorithmic-art.description = "Anthropic skill: algorithmic art generation";
    brand-guidelines.description = "Anthropic skill: brand guideline creation";
    canvas-design.description = "Anthropic skill: canvas design assistance";
    claude-api.description = "Anthropic skill: Claude API development guidance";
    doc-coauthoring.description = "Anthropic skill: document co-authoring";
    docx.description = "Anthropic skill: Word document manipulation";
    frontend-design.description = "Anthropic skill: frontend design guidance";
    internal-comms.description = "Anthropic skill: internal communications drafting";
    mcp-builder.description = "Anthropic skill: MCP server building";
    pdf.description = "Anthropic skill: PDF document handling";
    pptx.description = "Anthropic skill: PowerPoint presentation creation";
    skill-creator.description = "Anthropic skill: scaffolding for authoring new agent skills";
    slack-gif-creator.description = "Anthropic skill: Slack GIF creation";
    theme-factory.description = "Anthropic skill: theme generation";
    web-artifacts-builder.description = "Anthropic skill: web artifact building";
    webapp-testing.description = "Anthropic skill: web application testing";
    xlsx.description = "Anthropic skill: Excel spreadsheet manipulation";
  };

  custom = {
    hello-world.description = "Custom skill: hello-world scaffold";
  };
}
