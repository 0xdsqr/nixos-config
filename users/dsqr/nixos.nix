{ pkgs, inputs, ... }:

{
  # add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.fish.enable = true;

  users.users.dsqr = {
    isNormalUser = true;
    home = "/home/dsqr";
    extraGroups = [
      "docker"
      "lxd"
      "wheel"
      "networkmanager"
    ];
    description = "its me dave";
    hashedPassword = "$6$eupftIGTj5TR3pZE$UKnZlQkUxWJpLUcYjVKtDP23b0p5c2tf66qyBZJZL7/ZrITmQ1epwjmQe0gKxzJuaUKZ8jlW/CyfrCcICIvN.0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfvrJELCv6dQp2VoceeVrtx1e0mnVo2FgNgu9o98BtF me@dsqr.dev"
    ];
  };
}
