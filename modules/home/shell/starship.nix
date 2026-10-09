{lib, ...}: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    # The full config (format + palette) is a skein template rendered live
    # to ~/.cache/skein/starship.toml on every theme change. HM still owns
    # the package + shell integration; the file it writes is unused.
    # stylix starship target stays off so they never fight.
  };

  # Point starship at the live-rendered config. Missing file (fresh boot
  # before the daemon) falls back to starship defaults, not an error.
  # mkForce: the HM starship module sets this to its own static config.
  home.sessionVariables = {
    STARSHIP_CONFIG = lib.mkForce "/home/manpreet/.cache/skein/starship.toml";
  };
}
