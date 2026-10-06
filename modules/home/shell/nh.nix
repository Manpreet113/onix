{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.nh = {
    enable = true;
    flake = "/home/manpreet/onix";
  };
}
