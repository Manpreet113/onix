{pkgs, ...}: {
  # Browsers, packaged in-tree (pkgs/): zen stable is the default,
  # helium (Chromium) exists for Chromium-only webapps: `helium --app=<url>`.
  home.packages = with pkgs; [
    zen-browser
    helium-browser
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "zen.desktop";
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "x-scheme-handler/about" = "zen.desktop";
      "x-scheme-handler/unknown" = "zen.desktop";
      "application/xhtml+xml" = "zen.desktop";
      "application/pdf" = "zen.desktop";
    };
  };

  home.sessionVariables = {
    BROWSER = "zen";
    DEFAULT_BROWSER = "zen";
  };

  # Live wallpaper-driven chrome: skein deploys zen-userChrome.css into the
  # profile's chrome dir on every theme change (see services.skein deploy
  # targets). userChrome.css just imports it; the stylesheets pref enables
  # the whole mechanism. Profile dir has a random suffix — stable absent a
  # profile refresh. Startup-only: restart Zen after a theme switch.
  # (Filenames with spaces/dots are fine as single attr names.)
  home.file.".config/zen/ejbelto2.Default Profile/user.js".text = ''
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
  '';
  home.file.".config/zen/ejbelto2.Default Profile/chrome/userChrome.css".text = ''
    @import url("zen-userChrome.css");
  '';

  # Chromium-only webapps run on helium (zen stays the default browser).
  # See modules/home/webapps.nix for the 5-line recipe to add more.
  onix.webapps.whatsapp = {
    displayName = "WhatsApp";
    url = "https://web.whatsapp.com";
    iconUrl = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/whatsapp.svg";
    iconSha256 = "sha256-Yp/4FGnBIAoAw85w2Cmuj6pIcvpPeG2tiQ1klmaV/UI=";
    categories = ["Network" "Chat"];
  };
}
