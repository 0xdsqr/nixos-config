{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  allowedUsers = "618575437995442197,980636531565949019";
  bundledSkills = map (path: builtins.baseNameOf (builtins.dirOf path)) (
    builtins.filter (path: lib.hasSuffix "/SKILL.md" (toString path)) (
      lib.filesystem.listFilesRecursive (inputs.hermes-agent + /skills)
    )
  );
  curateSkills = enabled: { disabled = lib.subtractLists enabled bundledSkills; };
  enabledSkills = [
    "architecture-diagram"
    "arxiv"
    "ascii-art"
    "ascii-video"
    "baoyu-infographic"
    "blogwatcher"
    "claude-design"
    "codebase-inspection"
    "codex"
    "comfyui"
    "computer-use"
    "design-md"
    "docx"
    "excalidraw"
    "gif-search"
    "github-auth"
    "github-code-review"
    "github-issues"
    "github-pr-workflow"
    "github-repo-management"
    "google-workspace"
    "grounded-citations"
    "hermes-agent"
    "hermes-agent-skill-authoring"
    "humanizer"
    "llm-wiki"
    "manim-video"
    "maps"
    "nano-pdf"
    "node-inspect-debugger"
    "ocr-and-documents"
    "p5js"
    "pdf"
    "plan"
    "popular-web-designs"
    "powerpoint"
    "pretext"
    "python-debugpy"
    "requesting-code-review"
    "research-paper-writing"
    "simplify-code"
    "sketch"
    "songsee"
    "songwriting-and-ai-music"
    "spike"
    "systematic-debugging"
    "test-driven-development"
    "touchdesigner-mcp"
    "xlsx"
    "youtube-content"
  ];
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
    memory_notifications = false;
    show_commentary = false;
    show_reasoning = false;
    tool_progress = "off";
  };
  model = {
    default = "gpt-5.6-sol";
    provider = "openai-codex";
  };
  cognition = {
    auxiliary.compression = {
      provider = "main";
      reasoning_effort = "low";
    };
    compression = {
      enabled = true;
      threshold = 0.85;
      target_ratio = 0.20;
      protect_last_n = 20;
      min_tail_user_messages = 3;
      in_place = true;
      micro_compact = false;
    };
    memory = {
      memory_enabled = true;
      user_profile_enabled = true;
      memory_char_limit = 2200;
      user_char_limit = 1375;
      write_approval = false;
    };
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
  services.hermes-agent.extraPackages = [ pkgs.binutils ];

  age.secrets.hermes-providers-environment = {
    file = ../hermes-providers.env.age;
    owner = "hermes";
    group = "hermes";
    mode = "0440";
  };

  _module.args.hermesShared = {
    inherit
      allowedUsers
      cognition
      commonToolsets
      curateSkills
      display
      enabledSkills
      model
      providers
      resources
      ;
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
    opusLibraryPath = lib.makeLibraryPath [ pkgs.libopus ];
    providersEnvironmentFile = config.age.secrets.hermes-providers-environment.path;
  };
}
