{
  flake.darwinModules."window-manager" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) getAttr mapAttrs mapAttrsToList;
      inherit (lib.fixedPoints) fix;
      inherit (lib.lists) foldl' map optionals;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.options) mkEnableOption;
      inherit (lib.strings) charToInt concatLines escapeShellArgs;
      cfg = config.dsqr.darwin.desktop.windowManager;

      keyCodes =
        (mapAttrs
          (char: code: {
            char = charToInt char;
            inherit code;
          })
          {
            a = 0;
            b = 11;
            c = 8;
            d = 2;
            e = 14;
            f = 3;
            g = 5;
            h = 4;
            i = 34;
            j = 38;
            k = 40;
            l = 37;
            m = 46;
            n = 45;
            o = 31;
            p = 35;
            q = 12;
            r = 15;
            s = 1;
            t = 17;
            u = 32;
            v = 9;
            w = 13;
            x = 7;
            y = 16;
            z = 6;
          }
        )
        // {
          backspace = {
            char = 65535;
            code = 51;
          };
          tab = {
            char = 65535;
            code = 48;
          };
        };

      modifierMasks = fix (self: {
        shift = 131072;
        control = 262144;
        option = 524288;
        command = 1048576;
        super = self.command + self.control;
      });

      hotkey = key: modifiers: {
        enabled = 1;
        value = {
          type = "standard";
          parameters = [
            keyCodes.${key}.char
            keyCodes.${key}.code
            (foldl' (total: modifier: total + getAttr modifier modifierMasks) 0 modifiers)
          ];
        };
      };

      symbolicHotkeys = {
        # Save / copy full screen.
        "28" = hotkey "s" [ "super" ];
        "29" = hotkey "s" [
          "super"
          "option"
        ];

        # Save / copy / record selected area.
        "30" = hotkey "a" [ "super" ];
        "31" = hotkey "a" [
          "super"
          "option"
        ];
        "184" = hotkey "a" [
          "super"
          "shift"
        ];

        # Previous / next input source.
        "60" = hotkey "tab" [
          "super"
          "option"
          "shift"
        ];
        "61" = hotkey "tab" [
          "super"
          "option"
        ];

        # Spotlight search launcher.
        "64" = hotkey "backspace" [ "super" ];

        # Keyboard focus/navigation shortcuts handled by the WM layer.
        "7".enabled = 0;
        "8".enabled = 0;
        "9".enabled = 0;
        "10".enabled = 0;
        "11".enabled = 0;
        "12".enabled = 0;
        "13".enabled = 0;
        "27".enabled = 0;

        # Accessibility zoom/display toggles and contrast controls.
        "15".enabled = 0;
        "17".enabled = 0;
        "19".enabled = 0;
        "21".enabled = 0;
        "23".enabled = 0;
        "25".enabled = 0;
        "26".enabled = 0;

        # Mission Control all-windows overview conflicts with the Hammerspoon close-window binding.
        "32".enabled = 0;

        # Mission Control variants, desktop reveal, Dock toggle, status focus, VoiceOver.
        "33".enabled = 0;
        "34".enabled = 0;
        "35".enabled = 0;
        "36".enabled = 0;
        "37".enabled = 0;
        "52".enabled = 0;
        "53".enabled = 0;
        "54".enabled = 0;
        "57".enabled = 0;
        "59".enabled = 0;

        # Finder search, space switching, help, handwriting, context menu, accessibility controls.
        "65".enabled = 0;
        "79".enabled = 0;
        "80".enabled = 0;
        "81".enabled = 0;
        "82".enabled = 0;
        "98".enabled = 0;
        "156".enabled = 0;
        "159".enabled = 0;
        "162".enabled = 0;
        "164".enabled = 0;

        # Touch Bar capture, Quick Note, minimize, and native tiling shortcuts.
        "181".enabled = 0;
        "182".enabled = 0;
        "190".enabled = 0;
        "233".enabled = 0;
        "237".enabled = 0;
        "238".enabled = 0;
        "239".enabled = 0;
        "240".enabled = 0;
        "241".enabled = 0;
        "242".enabled = 0;
        "243".enabled = 0;
        "248".enabled = 0;
        "249".enabled = 0;
        "250".enabled = 0;
        "251".enabled = 0;
      };

      reloadSymbolicHotkey = pkgs.stdenv.mkDerivation {
        pname = "reload-symbolic-hotkey";
        version = "1.0.0";

        src = pkgs.writeText "reload-symbolic-hotkey.c" /* c */ ''
          #include <stdbool.h>
          #include <stdint.h>
          #include <stdio.h>
          #include <stdlib.h>

          typedef int32_t CGError;
          typedef int32_t CGSSymbolicHotKey;
          typedef uint16_t CGKeyCode;
          typedef uint32_t CGSModifierFlags;
          typedef uint16_t unichar;

          extern CGError CGSSetSymbolicHotKeyEnabled(CGSSymbolicHotKey hotKey, bool enabled);
          extern CGError CGSSetSymbolicHotKeyValue(
              CGSSymbolicHotKey hotKey,
              unichar keyEquivalent,
              CGKeyCode virtualKeyCode,
              CGSModifierFlags modifiers);

          static uint32_t parseUint32(const char *value) {
            char *end = NULL;
            unsigned long parsed = strtoul(value, &end, 10);

            if (end == value || *end != '\0' || parsed > UINT32_MAX) {
              fprintf(stderr, "invalid integer: %s\n", value);
              exit(2);
            }

            return (uint32_t)parsed;
          }

          int main(int argc, char **argv) {
            if (argc != 3 && argc != 6) {
              fprintf(stderr, "usage: %s <id> <enabled> [char keycode modifiers]\n", argv[0]);
              return 2;
            }

            CGSSymbolicHotKey id = (CGSSymbolicHotKey)parseUint32(argv[1]);
            bool enabled = parseUint32(argv[2]) != 0;

            CGError value_error = 0;
            if (argc == 6) {
              unichar key_equivalent = (unichar)parseUint32(argv[3]);
              CGKeyCode virtual_key_code = (CGKeyCode)parseUint32(argv[4]);
              CGSModifierFlags modifiers = (CGSModifierFlags)parseUint32(argv[5]);
              value_error = CGSSetSymbolicHotKeyValue(id, key_equivalent, virtual_key_code, modifiers);
            }

            CGError enabled_error = CGSSetSymbolicHotKeyEnabled(id, enabled);

            return value_error == 0 && enabled_error == 0 ? 0 : 1;
          }
        '';

        dontUnpack = true;
        dontConfigure = true;

        buildPhase = /* bash */ ''
          $CC -O2 -Wall -Wextra \
            -framework CoreGraphics \
            -o reload-symbolic-hotkey "$src"
        '';

        installPhase = /* bash */ ''
          mkdir -p "$out/bin"
          install -m755 reload-symbolic-hotkey "$out/bin/"
        '';

        meta.mainProgram = "reload-symbolic-hotkey";
      };

      hotkeyArgs =
        id:
        {
          enabled,
          value ? null,
        }:
        [
          id
          (toString enabled)
        ]
        ++ optionals (value != null) (map toString value.parameters);

      reloadSymbolicHotkeysScript = pkgs.writeShellScript "reload-symbolic-hotkeys-per-user" (
        concatLines (
          mapAttrsToList (id: value: "${getExe reloadSymbolicHotkey} ${escapeShellArgs (hotkeyArgs id value)}") symbolicHotkeys
        )
      );
    in
    {
      options.dsqr.darwin.desktop.windowManager.enable = mkEnableOption "desktop window-manager defaults";

      config = mkIf cfg.enable {
        system.defaults.NSGlobalDomain = {
          _HIHideMenuBar = false;
          AppleEnableMouseSwipeNavigateWithScrolls = false;
          AppleEnableSwipeNavigateWithScrolls = false;
          AppleKeyboardUIMode = 3;
          ApplePressAndHoldEnabled = false;
          AppleScrollerPagingBehavior = true;
          AppleShowScrollBars = "WhenScrolling";
          AppleSpacesSwitchOnActivate = false;
          AppleWindowTabbingMode = "always";
          InitialKeyRepeat = 10;
          KeyRepeat = 1;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticInlinePredictionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSNavPanelExpandedStateForSaveMode = true;
          NSScrollAnimationEnabled = true;
          NSWindowResizeTime = 0.003;
          NSWindowShouldDragOnGesture = true;
          PMPrintingExpandedStateForPrint = true;
          "com.apple.keyboard.fnState" = false;
          "com.apple.trackpad.scaling" = 1.5;
        };

        system.defaults.CustomSystemPreferences."com.apple.AppleMultitouchTrackpad" = {
          FirstClickThreshold = 0;
          SecondClickThreshold = 0;
          TrackpadFourFingerHorizSwipeGesture = 0;
          TrackpadThreeFingerHorizSwipeGesture = 0;
          TrackpadThreeFingerVertSwipeGesture = 0;
        };
        system.defaults.CustomSystemPreferences."com.apple.CoreBrightness" = {
          "Keyboard Dim Time" = 60;
          KeyboardBacklight.KeyboardBacklightIdleDimTime = 60;
        };
        system.defaults.CustomSystemPreferences."com.apple.dock".workspaces-auto-swoosh = false;
        system.defaults.CustomSystemPreferences."com.apple.Accessibility".ReduceMotionEnabled = 1;
        system.defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys = symbolicHotkeys;
        system.defaults.universalaccess.reduceMotion = true;
        system.defaults.WindowManager.AppWindowGroupingBehavior = false;

        system.activationScripts.script.text = mkAfter /* bash */ ''
          ${config.system.activationScripts.symbolic-hotkeys.text}
        '';

        system.activationScripts.symbolic-hotkeys.text = /* bash */ ''
          echo "reloading symbolic hotkeys..."
          user=${lib.escapeShellArg config.system.primaryUser}
          uid="$(id -u "$user")"
          /bin/launchctl asuser "$uid" /usr/bin/sudo --user "$user" -- ${reloadSymbolicHotkeysScript}
        '';
      };
    };
}
