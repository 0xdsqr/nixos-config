_: {
  programs.tmux = {
    enable = true;
    shortcut = "Space";
    baseIndex = 1;
    newSession = true;
    escapeTime = 0;
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set-option -sa terminal-features ",xterm-ghostty:RGB"
      set-option -sa terminal-features ",tmux-256color:RGB"
      set -g mouse on
      set -g history-limit 100000
      set -g focus-events on
      set -g renumber-windows on
      set -g set-clipboard on
      set -g allow-passthrough on
      set -g status-position top
      set -g status-interval 5
      set -g status-left-length 40
      set -g status-right-length 80
      set -g status-left "#[bold] #S "
      set -g status-right "#[fg=colour245]%Y-%m-%d %H:%M "
      setw -g automatic-rename on
      setw -g aggressive-resize on

      unbind '"'
      unbind %
      bind - split-window -v -c "#{pane_current_path}"
      bind \\ split-window -h -c "#{pane_current_path}"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux: reloaded"
      bind c new-window -c "#{pane_current_path}"
      bind x kill-pane
    '';
  };
}
