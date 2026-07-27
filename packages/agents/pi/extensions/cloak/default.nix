{
  description = "Redact secrets from Pi tool results before they enter model context";
  enableByDefault = true;
  settings = {
    enabled = true;
    mask = "[REDACTED]";
    includeDefaultRules = true;
    rules = [ ];
    patterns = [ ];
  };
  settingsFile = "cloak.json";
  source = ./.;
}
