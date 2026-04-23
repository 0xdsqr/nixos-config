{
  bundledPlugins = {
    # Bundled plugins come from nix-openclaw's local plugin catalog:
    # summarize, peekaboo, poltergeist, sag, camsnap, gogcli, goplaces,
    # bird, sonoscli, imsg.
    #
    # The only actual Nix options for each bundled plugin are:
    #   enable = true;
    #   config = { ... };
    #
    # `config` is passed through to the plugin as-is, so env/settings/files
    # keys depend on the plugin itself. Everything below is commented out on
    # purpose so you can opt in one tool at a time later.

    # summarize = {
    #   enable = true;
    #   config = {
    #     env = {
    #       OPENAI_API_KEY = "/run/agenix/openai-api-key";
    #       ANTHROPIC_API_KEY = "/run/agenix/anthropic-api-key";
    #       XAI_API_KEY = "/run/agenix/xai-api-key";
    #       GEMINI_API_KEY = "/run/agenix/gemini-api-key";
    #       FIRECRAWL_API_KEY = "/run/agenix/firecrawl-api-key";
    #       APIFY_API_TOKEN = "/run/agenix/apify-api-token";
    #     };
    #     settings = { };
    #   };
    # };
    # Summarize URLs, PDFs, YouTube videos, and other long-form sources.

    # peekaboo = {
    #   enable = true;
    #   config = {
    #     env = { };
    #     settings = { };
    #   };
    # };
    # macOS-only screenshot capture and vision helper.

    # poltergeist = {
    #   enable = true;
    #   config = {
    #     env = { };
    #     settings = { };
    #   };
    # };
    # macOS-oriented file watching / automation helper.

    # sag = {
    #   enable = true;
    #   config = {
    #     env = {
    #       ELEVENLABS_API_KEY = "/run/agenix/elevenlabs-api-key";
    #       SAG_API_KEY = "/run/agenix/elevenlabs-api-key";
    #     };
    #     settings = { };
    #   };
    # };
    # ElevenLabs-backed text-to-speech.

    # camsnap = {
    #   enable = true;
    #   config = {
    #     env = { };
    #     settings = {
    #       # cameras = [ { name = "front-door"; url = "rtsp://..."; } ];
    #     };
    #   };
    # };
    # RTSP / ONVIF camera snapshots and clips.

    # gogcli = {
    #   enable = true;
    #   config = {
    #     env = {
    #       # Optional bootstrap env if you have one; most setup is OAuth.
    #     };
    #     settings = { };
    #   };
    # };
    # Google Workspace CLI for Gmail, Calendar, Drive, Docs, Sheets, Contacts.

    # goplaces = {
    #   enable = true;
    #   config = {
    #     env = {
    #       GOOGLE_PLACES_API_KEY = "/run/agenix/google-places-api-key";
    #     };
    #     settings = { };
    #   };
    # };
    # Google Places API (New) CLI.

    # bird = {
    #   enable = true;
    #   config = {
    #     env = {
    #       # Cookie/browser auth or other runtime auth goes here.
    #     };
    #     settings = { };
    #   };
    # };
    # X / Twitter integration.

    # sonoscli = {
    #   enable = true;
    #   config = {
    #     env = {
    #       SPOTIFY_CLIENT_ID = "/run/agenix/spotify-client-id";
    #       SPOTIFY_CLIENT_SECRET = "/run/agenix/spotify-client-secret";
    #     };
    #     settings = { };
    #   };
    # };
    # Sonos LAN control; Spotify creds are optional for search helpers.

    # imsg = {
    #   enable = true;
    #   config = {
    #     env = { };
    #     settings = { };
    #   };
    # };
    # macOS-only iMessage / SMS integration.
  };

  hooPlugins = [
    # Instance-level/community plugins for the live hoo gateway only.
    # Keep vanilla empty until you want the second gateway online.

    # { source = "github:openclaw/nix-steipete-tools?dir=tools/peekaboo"; }
    # { source = "github:joshp123/xuezh"; }
    # {
    #   source = "github:joshp123/padel-cli";
    #   config = {
    #     env = {
    #       PADEL_AUTH_FILE = "/run/agenix/padel-auth";
    #     };
    #     settings = {
    #       default_location = "CITY_NAME";
    #       preferred_times = [ "18:00" "20:00" ];
    #       preferred_duration = 90;
    #       venues = [
    #         {
    #           id = "VENUE_ID";
    #           alias = "VENUE_ALIAS";
    #           name = "VENUE_NAME";
    #           indoor = true;
    #           timezone = "TIMEZONE";
    #         }
    #       ];
    #     };
    #   };
    # }
  ];
}
