{
  flake.homeModules."darwin-wm" =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {
      xdg.configFile."hammerspoon/Spoons/PaperWM.spoon" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        source = pkgs.fetchFromGitHub {
          owner = "mogenson";
          repo = "PaperWM.spoon";
          rev = "88aa02ad9002d1b5697aeaf9fb27cdb5cedc4964";
          hash = "sha256-c6ltYZKLjZXXin8UaURY0xIrdFvA06aKxC5oty2FCdY=";
        };
      };

      xdg.configFile."hammerspoon/darwin-wm.lua" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        text = ''
          local M = {}

          local gap = ${toString osConfig.theme.padding}
          local mod = { "cmd", "ctrl" }
          local mod_shift = { "cmd", "ctrl", "shift" }
          local mod_alt = { "cmd", "ctrl", "alt" }

          local PaperWM = nil

          local function focused_window()
            return hs.window.focusedWindow()
          end

          local function launch_or_new_ghostty()
            local ghostty = hs.application.get("Ghostty")

            if not ghostty then
              hs.application.launchOrFocus("Ghostty")
              return
            end

            ghostty:activate()
            hs.eventtap.keyStroke({ "ctrl", "shift" }, "t", 0, ghostty)
          end

          local function resize_focused_window(dx, dy)
            local window = focused_window()
            if not window then return end

            local frame = window:frame()
            frame.w = math.max(320, frame.w + dx)
            frame.h = math.max(220, frame.h + dy)

            window:setFrame(frame)
          end

          local function tile_unit(x, y, w, h)
            local window = focused_window()
            if not window then return end

            local screen = window:screen():frame()
            local frame = {
              x = screen.x + (screen.w * x) + gap,
              y = screen.y + (screen.h * y) + gap,
              w = (screen.w * w) - (gap * 2),
              h = (screen.h * h) - (gap * 2),
            }

            window:setFrame(frame)
          end

          local function center_window()
            if PaperWM and PaperWM.actions and PaperWM.actions.center_window then
              PaperWM.actions.center_window()
              return
            end

            local window = focused_window()
            if not window then return end

            local screen = window:screen():frame()
            local width = math.floor(screen.w * 0.72)
            local height = math.floor(screen.h * 0.82)

            window:setFrame({
              x = screen.x + math.floor((screen.w - width) / 2),
              y = screen.y + math.floor((screen.h - height) / 2),
              w = width,
              h = height,
            })
          end

          function M.setup()
            hs.window.animationDuration = 0
            PaperWM = hs.loadSpoon("PaperWM")

            -- App launchers.
            hs.hotkey.bind(mod, "return", launch_or_new_ghostty)

            if PaperWM and PaperWM.actions then
              -- PaperWM focus.
              hs.hotkey.bind(mod, "left", function()
                PaperWM.actions.focus_left()
                center_window()
              end)
              hs.hotkey.bind(mod, "down", PaperWM.actions.focus_down)
              hs.hotkey.bind(mod, "up", PaperWM.actions.focus_up)
              hs.hotkey.bind(mod, "right", function()
                PaperWM.actions.focus_right()
                center_window()
              end)

              hs.hotkey.bind(mod, "h", function()
                PaperWM.actions.focus_left()
                center_window()
              end)
              hs.hotkey.bind(mod, "j", PaperWM.actions.focus_down)
              hs.hotkey.bind(mod, "k", PaperWM.actions.focus_up)
              hs.hotkey.bind(mod, "l", function()
                PaperWM.actions.focus_right()
                center_window()
              end)

              -- Swap.
              hs.hotkey.bind(mod_shift, "h", PaperWM.actions.swap_left)
              hs.hotkey.bind(mod_shift, "j", PaperWM.actions.swap_down)
              hs.hotkey.bind(mod_shift, "k", PaperWM.actions.swap_up)
              hs.hotkey.bind(mod_shift, "l", PaperWM.actions.swap_right)

              -- Slurp / barf.
              hs.hotkey.bind(mod_shift, "t", PaperWM.actions.slurp_in)
              hs.hotkey.bind(mod_shift, "g", PaperWM.actions.barf_out)

              -- Floating / centering.
              hs.hotkey.bind(mod, "f", PaperWM.actions.toggle_floating)
              hs.hotkey.bind(mod_alt, "f", PaperWM.actions.full_width)
            else
              -- Fallback focus.
              hs.hotkey.bind(mod, "left", hs.window.focusWindowWest)
              hs.hotkey.bind(mod, "down", hs.window.focusWindowSouth)
              hs.hotkey.bind(mod, "up", hs.window.focusWindowNorth)
              hs.hotkey.bind(mod, "right", hs.window.focusWindowEast)

              hs.hotkey.bind(mod, "h", hs.window.focusWindowWest)
              hs.hotkey.bind(mod, "j", hs.window.focusWindowSouth)
              hs.hotkey.bind(mod, "k", hs.window.focusWindowNorth)
              hs.hotkey.bind(mod, "l", hs.window.focusWindowEast)

              -- Fallback starter tiling.
              hs.hotkey.bind(mod_shift, "h", function() tile_unit(0.00, 0.00, 0.50, 1.00) end)
              hs.hotkey.bind(mod_shift, "l", function() tile_unit(0.50, 0.00, 0.50, 1.00) end)
              hs.hotkey.bind(mod_shift, "k", function() tile_unit(0.00, 0.00, 1.00, 0.50) end)
              hs.hotkey.bind(mod_shift, "j", function() tile_unit(0.00, 0.50, 1.00, 0.50) end)

              hs.hotkey.bind(mod_shift, "u", function() tile_unit(0.00, 0.00, 0.50, 0.50) end)
              hs.hotkey.bind(mod_shift, "i", function() tile_unit(0.50, 0.00, 0.50, 0.50) end)
              hs.hotkey.bind(mod_shift, "n", function() tile_unit(0.00, 0.50, 0.50, 0.50) end)
              hs.hotkey.bind(mod_shift, "m", function() tile_unit(0.50, 0.50, 0.50, 0.50) end)

              hs.hotkey.bind(mod, "f", function()
                local window = focused_window()
                if window then window:maximize() end
              end)
              hs.hotkey.bind(mod_alt, "f", function()
                local window = focused_window()
                if window then window:maximize() end
              end)
            end

            hs.hotkey.bind(mod, "c", center_window)
            hs.hotkey.bind(mod, "d", function()
              local window = focused_window()
              if window then window:close() end
            end)

            -- Small manual resize controls until we bring in a fuller tiler.
            hs.hotkey.bind(mod_alt, "h", function() resize_focused_window(-80, 0) end)
            hs.hotkey.bind(mod_alt, "j", function() resize_focused_window(0, 80) end)
            hs.hotkey.bind(mod_alt, "k", function() resize_focused_window(0, -80) end)
            hs.hotkey.bind(mod_alt, "l", function() resize_focused_window(80, 0) end)

            -- Quality-of-life.
            hs.hotkey.bind(mod, "r", hs.reload)
            hs.hotkey.bind(mod, "/", function()
              hs.hotkey.showHotkeys(mod, "/")
            end)

            if PaperWM then
              PaperWM.window_gap = gap
              PaperWM.window_ratios = { 0.5, 0.75, 1.0 }
              PaperWM:start()
            end
          end

          return M
        '';
      };
    };
}
