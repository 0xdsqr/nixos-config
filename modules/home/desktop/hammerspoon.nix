{
  flake.homeModules.hammerspoon =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.home.desktop.hammerspoon;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
    in
    {
      options.dsqr.home.desktop.hammerspoon.enable = mkEnableOption "Hammerspoon home configuration";

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = isDarwin;
          message = "dsqr.home.desktop.hammerspoon requires Darwin.";
        };

        xdg.configFile."hammerspoon/init.lua" = mkIf isDarwin {
          text = /* lua */ ''
            PaperWM = hs.loadSpoon("PaperWM")
            Swipe = hs.loadSpoon("Swipe")

            local super = { "cmd", "ctrl" }
            local super_shift = { "cmd", "ctrl", "shift" }
            local gap = 24
            local ghostty = "Ghostty"
            local browser = "Helium"

            local function placeGhostty()
              local app = hs.application.get(ghostty)
              if not app then return end

              local window = app:mainWindow()
              if not window then return end

              local screen = window:screen():frame()

              window:setFrame({
                x = screen.x + gap,
                y = screen.y + gap,
                w = screen.w - (gap * 2),
                h = screen.h - (gap * 2),
              })
            end

            local function placeFocusedWindow()
              local window = hs.window.focusedWindow()
              if not window then return end

              local screen = window:screen():frame()

              window:setFrame({
                x = screen.x + gap,
                y = screen.y + gap,
                w = screen.w - (gap * 2),
                h = screen.h - (gap * 2),
              })
            end

            local function currentSpaceIndex()
              local current_space = hs.spaces.activeSpaceOnScreen()
              local spaces = hs.spaces.allSpaces()[hs.screen.mainScreen():getUUID()]

              local current_index = nil
              for space_index, space in ipairs(spaces) do
                if space == current_space then
                  current_index = space_index
                  break
                end
              end

              return current_index
            end

            local function changeSpaceBy(offset)
              local spaces = hs.spaces.allSpaces()[hs.screen.mainScreen():getUUID()]
              local current_index = currentSpaceIndex()
              if not current_index or not spaces then return end

              local target_index = current_index + offset
              if target_index < 1 or target_index > #spaces then return end

              local target_space = spaces[target_index]
              if target_space then
                hs.spaces.gotoSpace(target_space)
              end
            end

            local function gotoSpace(index)
              local spaces = hs.spaces.allSpaces()[hs.screen.mainScreen():getUUID()]
              if not spaces then return end

              local target_space = spaces[index]
              if target_space then
                hs.spaces.gotoSpace(target_space)
              end
            end

            local function centerFocusedWindow()
              if PaperWM and PaperWM.actions and PaperWM.actions.center_window then
                PaperWM.actions.center_window()
              end
            end

            local function closeFocusedWindow()
              local window = hs.window.focusedWindow()
              if not window then return end

              window:close()
            end

            local function sendGhosttyKeystroke(mods, key)
              local app = hs.application.get(ghostty)
              if not app then return end

              app:activate()
              hs.eventtap.keyStroke(mods, key, 0, app)
            end

            hs.window.animationDuration = 0

            if PaperWM then
              PaperWM.window_gap = gap
              PaperWM.window_ratios = { 0.56, 0.72, 1.0 }
              PaperWM:start()
            end

            local function launchGhostty()
              local app = hs.application.get(ghostty)

              if not app then
                hs.application.launchOrFocus(ghostty)
                return
              end

              sendGhosttyKeystroke({ "ctrl", "shift" }, "t")
            end

            local function launchNeovimTab()
              local app = hs.application.get(ghostty)

              if not app then
                hs.application.launchOrFocus(ghostty)
                hs.timer.doAfter(0.2, function()
                  placeGhostty()
                  sendGhosttyKeystroke({ "ctrl", "shift" }, "t")
                  hs.timer.doAfter(0.1, function()
                    sendGhosttyKeystroke({}, "n")
                    sendGhosttyKeystroke({}, "v")
                    sendGhosttyKeystroke({}, "i")
                    sendGhosttyKeystroke({}, "m")
                    sendGhosttyKeystroke({}, "return")
                  end)
                end)
                return
              end

              sendGhosttyKeystroke({ "ctrl", "shift" }, "t")
              hs.timer.doAfter(0.1, function()
                sendGhosttyKeystroke({}, "n")
                sendGhosttyKeystroke({}, "v")
                sendGhosttyKeystroke({}, "i")
                sendGhosttyKeystroke({}, "m")
                sendGhosttyKeystroke({}, "return")
                hs.timer.doAfter(0.1, placeGhostty)
              end)
            end

            local function launchBrowser()
              hs.application.launchOrFocus(browser)
            end

            local function launchBrowserTab()
              local app = hs.application.get(browser)

              if not app then
                hs.application.launchOrFocus(browser)
                return
              end

              app:activate()
              hs.eventtap.keyStroke({ "cmd" }, "n", 0, app)
            end

            hs.hotkey.bind(super, "return", launchGhostty)
            hs.hotkey.bind(super, "padenter", launchGhostty)
            hs.hotkey.bind(super, "n", launchNeovimTab)

            hs.hotkey.bind(super_shift, "return", launchBrowser)
            hs.hotkey.bind(super_shift, "padenter", launchBrowser)
            hs.hotkey.bind(super_shift, "p", launchBrowserTab)

            hs.hotkey.bind(super, "h", function()
              if PaperWM and PaperWM.actions then
                PaperWM.actions.focus_left()
                centerFocusedWindow()
              end
            end)

            hs.hotkey.bind(super, "l", function()
              if PaperWM and PaperWM.actions then
                PaperWM.actions.focus_right()
                centerFocusedWindow()
              end
            end)

            hs.hotkey.bind(super, "tab", function() changeSpaceBy(1) end)
            hs.hotkey.bind(super_shift, "tab", function() changeSpaceBy(-1) end)

            for index = 1, 9 do
              hs.hotkey.bind(super, tostring(index), function() gotoSpace(index) end)
              hs.hotkey.bind(super_shift, tostring(index), function()
                if PaperWM and PaperWM.actions then
                  local action = PaperWM.actions["move_window_" .. index]
                  if action then action() end
                end
              end)
            end

            hs.hotkey.bind(super, "c", centerFocusedWindow)
            hs.hotkey.bind(super, "f", function()
              if PaperWM and PaperWM.actions and PaperWM.actions.toggle_floating then
                PaperWM.actions.toggle_floating()
              end
            end)
            hs.hotkey.bind({ "cmd", "ctrl", "alt" }, "f", function()
              if PaperWM and PaperWM.actions and PaperWM.actions.full_width then
                PaperWM.actions.full_width()
              end
            end)
            hs.hotkey.bind(super, "o", closeFocusedWindow)
            hs.hotkey.bind(super, "r", hs.reload)
            hs.hotkey.bind(super, "/", function()
              hs.eventtap.keyStroke({ "cmd", "ctrl", "shift" }, "4")
            end)
            hs.hotkey.bind(super_shift, "/", function()
              hs.task.new("/bin/zsh", nil, {
                "-lc",
                "tmp=$(mktemp /tmp/hammerspoon-shot-XXXXXX.png) && /usr/sbin/screencapture -i \"$tmp\" && osascript -e 'set the clipboard to (read (POSIX file \\\"'\"$tmp\"'\\\") as «class PNGf»)' && rm -f \"$tmp\"",
              }):start()
            end)
          '';
        };
      };
    };
}
