{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  allowedUsers = "618575437995442197,980636531565949019";
  commonToolsets = [
    "a2a"
    "browser"
    "clarify"
    "code_execution"
    "cronjob"
    "delegation"
    "file"
    "image_gen"
    "memory"
    "session_search"
    "skills"
    "terminal"
    "todo"
    "tts"
    "video"
    "video_gen"
    "vision"
    "web"
  ];
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
  providers = {
    context.engine = "compressor";
    image_gen = {
      provider = "fal";
      model = "fal-ai/gpt-image-2";
      use_gateway = false;
    };
    stt = {
      enabled = true;
      echo_transcripts = false;
      provider = "elevenlabs";
      language = "en";
      elevenlabs = {
        model_id = "scribe_v2";
        language_code = "eng";
        tag_audio_events = false;
        diarize = false;
      };
    };
    tts = {
      provider = "elevenlabs";
      elevenlabs.model_id = "eleven_multilingual_v2";
    };
    video_gen = {
      provider = "fal";
      model = "pixverse-v6";
    };
  };
  resources = {
    CPUQuota = "150%";
    MemoryHigh = "1536M";
    MemoryMax = "2G";
    TasksMax = 512;
  };
in
{
  age.secrets.hermes-providers-environment = {
    file = ../hermes-providers.env.age;
    owner = "hermes";
    group = "hermes";
    mode = "0440";
  };

  _module.args.hermesShared = {
    inherit
      allowedUsers
      commonToolsets
      display
      model
      providers
      resources
      ;
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
    opusLibraryPath = lib.makeLibraryPath [ pkgs.libopus ];
    providersEnvironmentFile = config.age.secrets.hermes-providers-environment.path;
  };
}
