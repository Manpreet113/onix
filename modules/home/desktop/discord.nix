_: {
  programs.nixcord = {
    enable = true;
    discord.vencord.enable = true;

    # Nord-flavoured QuickCSS lives here when you want it:
    # quickCss = ''
    #   :root { --background-primary: #2e3440; }
    # '';
    # config = {
    #   useQuickCss = true;
    #   frameless = true;
    #   plugins = {
    #     # MessageLogger.enable = true;
    #   };
    # };
  };
}
