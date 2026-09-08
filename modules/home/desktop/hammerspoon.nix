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
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;

      cfg = config.dsqr.home.desktop.hammerspoon;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
    in
    {
      options.dsqr.home.desktop.hammerspoon = {
        enable = mkEnableOption "Hammerspoon home configuration";

        browserApplication = mkOption {
          type = str;
          default = "Helium";
          description = "macOS application name opened by Hammerspoon browser hotkeys.";
        };

        slackApplication = mkOption {
          type = str;
          default = "Slack";
          description = "macOS application name opened by the Hammerspoon Slack hotkey.";
        };
      };

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = isDarwin;
          message = "dsqr.home.desktop.hammerspoon requires Darwin.";
        };

        xdg.configFile."hammerspoon/init.lua" = mkIf isDarwin {
          text = /* lua */ ''
            ---@type table
            _G.hs = _G.hs

            PaperWM = hs.loadSpoon("PaperWM")
            Swipe = hs.loadSpoon("Swipe")

            local super = { "cmd", "ctrl" }
            local super_alt = { "cmd", "ctrl", "alt" }
            local super_shift = { "cmd", "ctrl", "shift" }
            local gap = 24
            local ghostty = "Ghostty"
            local browser = ${builtins.toJSON cfg.browserApplication}
            local slack = ${builtins.toJSON cfg.slackApplication}

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
              local screen = hs.screen.mainScreen()
              if not screen then return nil end

              local spaces = hs.spaces.allSpaces()[screen:getUUID()]
              if not spaces then return nil end

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
              if offset == 0 then return end

              local screen = hs.screen.mainScreen()
              if not screen then return end

              local spaces = hs.spaces.allSpaces()[screen:getUUID()]
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
              local screen = hs.screen.mainScreen()
              if not screen then return end

              local spaces = hs.spaces.allSpaces()[screen:getUUID()]
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

            local function paperAction(name)
              return function()
                if PaperWM and PaperWM.actions and PaperWM.actions[name] then
                  PaperWM.actions[name]()
                end
              end
            end

            local function focusPaperWindow(name, should_center)
              if PaperWM and PaperWM.actions and PaperWM.actions[name] then
                PaperWM.actions[name]()
                if should_center then centerFocusedWindow() end
              end
            end

            local function resizeFocusedWindow(offset_width, offset_height)
              local window = hs.window.focusedWindow()
              if not window then return end

              local window_frame = window:frame()
              local screen_frame = window:screen():frame()

              window_frame.w = window_frame.w + offset_width
              window_frame.w = math.max(100, math.min(window_frame.w, screen_frame.w - window_frame.x))

              window_frame.h = window_frame.h + offset_height
              window_frame.h = math.max(100, math.min(window_frame.h, screen_frame.h - window_frame.y))

              window:setFrame(window_frame)
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
              PaperWM.swipe_fingers = 3
              PaperWM.swipe_gain = 1.7
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

            local function launchSlack()
              hs.application.launchOrFocus(slack)
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

            local function captureSelectionToClipboard()
              hs.task.new("/usr/sbin/screencapture", nil, { "-ic" }):start()
            end

            hs.hotkey.bind(super, "return", launchGhostty)
            hs.hotkey.bind(super, "padenter", launchGhostty)
            hs.hotkey.bind(super, "n", launchNeovimTab)

            hs.hotkey.bind(super_shift, "return", launchBrowser)
            hs.hotkey.bind(super_shift, "padenter", launchBrowser)
            hs.hotkey.bind(super_shift, "p", launchBrowserTab)
            hs.hotkey.bind(super, "w", launchBrowser)
            hs.hotkey.bind(super_shift, "s", launchSlack)
            hs.hotkey.bind(super, "t", function() hs.application.launchOrFocus("Finder") end)

            hs.hotkey.bind(super, "h", function() focusPaperWindow("focus_left", true) end)
            hs.hotkey.bind(super, "left", function() focusPaperWindow("focus_left", true) end)
            hs.hotkey.bind(super, "j", function() focusPaperWindow("focus_down", false) end)
            hs.hotkey.bind(super, "down", function() focusPaperWindow("focus_down", false) end)
            hs.hotkey.bind(super, "k", function() focusPaperWindow("focus_up", false) end)
            hs.hotkey.bind(super, "up", function() focusPaperWindow("focus_up", false) end)
            hs.hotkey.bind(super, "l", function() focusPaperWindow("focus_right", true) end)
            hs.hotkey.bind(super, "right", function() focusPaperWindow("focus_right", true) end)

            hs.hotkey.bind(super_alt, "h", function() resizeFocusedWindow(-100, 0) end)
            hs.hotkey.bind(super_alt, "left", function() resizeFocusedWindow(-100, 0) end)
            hs.hotkey.bind(super_alt, "j", function() resizeFocusedWindow(0, 100) end)
            hs.hotkey.bind(super_alt, "down", function() resizeFocusedWindow(0, 100) end)
            hs.hotkey.bind(super_alt, "k", function() resizeFocusedWindow(0, -100) end)
            hs.hotkey.bind(super_alt, "up", function() resizeFocusedWindow(0, -100) end)
            hs.hotkey.bind(super_alt, "l", function() resizeFocusedWindow(100, 0) end)
            hs.hotkey.bind(super_alt, "right", function() resizeFocusedWindow(100, 0) end)

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

            hs.hotkey.bind(super_shift, "h", paperAction("swap_left"))
            hs.hotkey.bind(super_shift, "left", paperAction("swap_left"))
            hs.hotkey.bind(super_shift, "j", paperAction("swap_down"))
            hs.hotkey.bind(super_shift, "down", paperAction("swap_down"))
            hs.hotkey.bind(super_shift, "k", paperAction("swap_up"))
            hs.hotkey.bind(super_shift, "up", paperAction("swap_up"))
            hs.hotkey.bind(super_shift, "l", paperAction("swap_right"))
            hs.hotkey.bind(super_shift, "right", paperAction("swap_right"))
            hs.hotkey.bind(super_shift, "t", paperAction("slurp_in"))
            hs.hotkey.bind(super_shift, "g", paperAction("barf_out"))

            hs.hotkey.bind(super, "c", centerFocusedWindow)
            hs.hotkey.bind(super, "f", paperAction("toggle_floating"))
            hs.hotkey.bind(super_alt, "f", paperAction("full_width"))
            hs.hotkey.bind(super, "o", closeFocusedWindow)
            hs.hotkey.bind(super, "r", hs.reload)
            hs.hotkey.bind(super, "/", captureSelectionToClipboard)
            hs.hotkey.bind(super_shift, "/", captureSelectionToClipboard)

            if Swipe then
              local current_id, threshold

              Swipe:start(3, function(direction, distance, id)
                if id ~= current_id then
                  current_id = id
                  threshold = 0.2
                  return
                end

                if distance > threshold then
                  threshold = math.huge

                  if direction == "up" then
                    changeSpaceBy(1)
                  elseif direction == "down" then
                    changeSpaceBy(-1)
                  end
                end
              end)
            end

            do
              local space_buttons = {}

              local function updateSpaceButtons()
                for _, button in pairs(space_buttons) do
                  button:delete()
                end
                space_buttons = {}

                local screen = hs.screen.mainScreen()
                if not screen then return end

                local spaces_by_screen = hs.spaces.allSpaces()
                local spaces = spaces_by_screen[screen:getUUID()]
                if not spaces then return end

                local current_space = hs.spaces.activeSpaceOnScreen()

                for index = #spaces, 1, -1 do
                  local space = spaces[index]
                  local title = tostring(index)
                  local attributes = space == current_space and { color = { red = 1 } } or {}
                  local button = hs.menubar.new()

                  button:setTitle(hs.styledtext.new(title, attributes))
                  button:setClickCallback(function() gotoSpace(index) end)

                  table.insert(space_buttons, button)
                end
              end

              _G.dsqr_space_watcher = hs.spaces.watcher.new(updateSpaceButtons)
              _G.dsqr_space_watcher:start()
              updateSpaceButtons()
            end
          '';
        };
      };
    };
}
