{
  "$schema" =
    "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
  name = "dsqr-midnight";

  vars = {
    base = "#171520";
    mantle = "#1d1a2a";
    surface0 = "#272337";
    surface1 = "#352f49";
    surface2 = "#49415f";
    selection = "#3c3157";

    text = "#c8cbed";
    subtext = "#a9acd0";
    muted = "#8589aa";
    dim = "#656985";

    mauve = "#b69df1";
    lavender = "#aeb8ee";
    pink = "#dfa6d5";
    red = "#e17d8e";
    peach = "#e6a17f";
    yellow = "#dcc38a";
    green = "#9bca8c";
    teal = "#83c7bd";
    cyan = "#82c5d8";
    blue = "#82a5e8";

    toolSuccessBg = "#1b2728";
    toolErrorBg = "#2a1c28";
  };

  colors = {
    accent = "mauve";
    border = "surface1";
    borderAccent = "mauve";
    borderMuted = "surface2";
    success = "green";
    error = "red";
    warning = "yellow";
    muted = "muted";
    dim = "dim";
    text = "text";
    thinkingText = "subtext";

    selectedBg = "selection";
    userMessageBg = "surface0";
    userMessageText = "text";
    customMessageBg = "mantle";
    customMessageText = "text";
    customMessageLabel = "pink";
    toolPendingBg = "mantle";
    toolSuccessBg = "toolSuccessBg";
    toolErrorBg = "toolErrorBg";
    toolTitle = "blue";
    toolOutput = "subtext";

    mdHeading = "mauve";
    mdLink = "blue";
    mdLinkUrl = "cyan";
    mdCode = "green";
    mdCodeBlock = "text";
    mdCodeBlockBorder = "surface2";
    mdQuote = "yellow";
    mdQuoteBorder = "mauve";
    mdHr = "surface2";
    mdListBullet = "lavender";

    toolDiffAdded = "green";
    toolDiffRemoved = "red";
    toolDiffContext = "muted";

    syntaxComment = "dim";
    syntaxKeyword = "mauve";
    syntaxFunction = "blue";
    syntaxVariable = "pink";
    syntaxString = "green";
    syntaxNumber = "peach";
    syntaxType = "yellow";
    syntaxOperator = "cyan";
    syntaxPunctuation = "subtext";

    thinkingOff = "surface2";
    thinkingMinimal = "lavender";
    thinkingLow = "blue";
    thinkingMedium = "teal";
    thinkingHigh = "mauve";
    thinkingXhigh = "pink";
    thinkingMax = "red";

    bashMode = "peach";
  };

  export = {
    pageBg = "#111019";
    cardBg = "#1d1a2a";
    infoBg = "#272337";
  };
}
