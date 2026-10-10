_: {
  programs.nixcord = {
    enable = true;
    discord.vencord.enable = true;

    # Live wallpaper-driven theme: skein deploys skein.theme.css into
    # Vencord's themes dir on every theme change (see services.skein
    # deploy targets). Enabled here; Vencord picks up file changes live.
    # Missing file at first boot is a silent no-op.
    config = {
      enabledThemes = ["skein.css"];
      frameless = true;
    };
  };
}
