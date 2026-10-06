{ config, lib, pkgs, ... }: {
  services.mako = {
    enable = true;
    settings = {
      background-color = "#282828";
      text-color = "#ebdbb2";
      border-color = "#458588";
      border-radius = 8;
      border-size = 2;
      default-timeout = 5000;
      font = "JetBrainsMono Nerd Font 10";
      padding = "10";
      margin = "10";
      width = 350;
      height = 150;
      anchor = "top-right";
      "urgency=low" = {
        background-color = "#3c3836";
      };
      "urgency=high" = {
        border-color = "#cc241d";
        background-color = "#cc241d";
      };
    };
  };
}
