{lib, ...}: {
  # Helper to check if ghostty exists in pkgs
  hasGhostty = pkgs: builtins.hasAttr "ghostty" pkgs;
}
