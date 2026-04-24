_: {
  dsqr.nixos.alloy.loki.journalProcessStages = ''
    stage.match {
      selector = "{unit=\"cloudflared-managed-tunnel.service\"} |= \"dest=\""

      stage.regex {
        expression = ".*dest=(?P<dest>\\S+).*"
      }

      stage.regex {
        source     = "dest"
        expression = "^(?:https?://)?(?P<dest_host>[^/:?]+)"
      }

      stage.labels {
        values = {
          dest_host = "",
        }
      }
    }

    stage.match {
      selector = "{unit=\"cloudflared-managed-tunnel.service\"} |= \"originService=\""

      stage.regex {
        expression = ".*originService=(?P<origin_service>\\S+).*"
      }

      stage.regex {
        source     = "origin_service"
        expression = "^(?:https?://)?(?P<origin_host>[^/:?]+)"
      }

      stage.labels {
        values = {
          origin_host = "",
        }
      }
    }
  '';
}
