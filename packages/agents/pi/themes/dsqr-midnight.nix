{
  "$schema" =
    "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
  name = "dsqr-midnight";

  vars = {
    base = "#18151e";
    mantle = "#211d2a";
    surface0 = "#2a2535";
    surface1 = "#373044";
    surface2 = "#4a4058";
    selection = "#463654";

    text = "#ded7e8";
    subtext = "#b5aec4";
    muted = "#8f879d";
    dim = "#6d6678";

    mauve = "#c8a2d0";
    lavender = "#b9b6df";
    pink = "#d3a1bd";
    red = "#d98894";
    peach = "#daa17e";
    yellow = "#d7bd85";
    green = "#9fbd8b";
    teal = "#8ab9aa";
    cyan = "#87b7c4";
    blue = "#91a8d0";

    toolSuccessBg = "#242130";
    toolErrorBg = "#2c2029";
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
    thinkingText = "muted";

    selectedBg = "selection";
    userMessageBg = "surface0";
    userMessageText = "text";
    customMessageBg = "mantle";
    customMessageText = "text";
    customMessageLabel = "pink";
    toolPendingBg = "mantle";
    toolSuccessBg = "toolSuccessBg";
    toolErrorBg = "toolErrorBg";
    toolTitle = "lavender";
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
    pageBg = "#121017";
    cardBg = "#211d2a";
    infoBg = "#2a2535";
  };
}
