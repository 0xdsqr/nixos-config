{ inputs, pkgs, ... }:
let
  allowedUsers = "618575437995442197,980636531565949019";
  display = {
    interim_assistant_messages = false;
    show_commentary = false;
    show_reasoning = false;
    tool_progress = "off";
  };
  model = {
    default = "gpt-5.6-sol";
    provider = "openai-codex";
  };
  resources = {
    CPUQuota = "150%";
    MemoryHigh = "1536M";
    MemoryMax = "2G";
    TasksMax = 512;
  };
in
{
  _module.args.hermesShared = {
    inherit
      allowedUsers
      display
      model
      resources
      ;
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.messaging;
  };
}
