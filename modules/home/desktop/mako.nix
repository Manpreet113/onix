{
  config,
  lib,
  pkgs,
  ...
}: {
  services.mako = {
    enable = true;
    settings = {
      border-radius = 8;
      border-size = 2;
      default-timeout = 5000;
      padding = "10";
      margin = "10";
      width = 350;
      height = 150;
      anchor = "top-right";
    };
  };
}
