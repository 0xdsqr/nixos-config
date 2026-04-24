# TOOLS.md - Local Notes

Notes about tools, devices, and environment-specific stuff.

## Discord Delivery (Cron / Proactive Messages)
- **My Discord account**: `vanilla`
- **My channel**: `1465807038587076700` (#vanilla)
- **⚠️ Cron auto-delivery (`deliver: true`) does NOT work reliably** with multi-account Discord.
  It falls back to account "default" which doesn't exist.
- **Fix**: When sending to Discord from cron or proactive contexts, use the `message` tool directly:
  ```
  message(action: "send", target: "channel:1465807038587076700", message: "...", accountId: "vanilla")
  ```
- Never rely on `deliver: true` for Discord cron jobs. Always use `deliver: false` + message tool.

## Browser (OpenClaw managed)
- Always use `profile: "openclaw"`
- Flow: `start` → `open` (get targetId) → `snapshot` (read page) → `act` (click/type) → `snapshot` again
- `snapshot` = structured text of the page (how I "read" it), returns element refs like `e12`
- `screenshot` = visual image of the page
- `act` with `kind: "click"`, `kind: "type"`, `kind: "press"` etc
- Always pass `targetId` from previous calls to stay on same tab
- `refs="aria"` gives stable refs across calls
- Chromium at `/usr/bin/chromium`, CDP port 18800

## What Goes Here

Things like:
- Preferred voices for TTS
- Device nicknames
- Shortcuts and preferences
- Anything environment-specific

---

*Add whatever helps you do your job. This is your cheat sheet.*
