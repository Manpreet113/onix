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

  # Chromium-only webapps run on helium (zen stays the default browser)
  xdg.desktopEntries.whatsapp = {
    name = "WhatsApp";
    exec = "helium --app=https://web.whatsapp.com";
    comment = "WhatsApp Web (Helium app window)";
    icon = "helium";
    categories = ["Network" "Chat"];
    startupNotify = true;
  };
}
