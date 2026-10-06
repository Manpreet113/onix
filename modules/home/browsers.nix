{
  config,
  lib,
  pkgs,
  ...
}: {
  # Browsers: zen via Flatpak (declarative via nix-flatpak), helium dropped
  # No nix firefox — removed. Zen is default for xdg mime.

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "app.zen_browser.zen.desktop";
      "x-scheme-handler/http" = "app.zen_browser.zen.desktop";
      "x-scheme-handler/https" = "app.zen_browser.zen.desktop";
      "x-scheme-handler/about" = "app.zen_browser.zen.desktop";
      "x-scheme-handler/unknown" = "app.zen_browser.zen.desktop";
      "application/xhtml+xml" = "app.zen_browser.zen.desktop";
      "application/pdf" = "app.zen_browser.zen.desktop";
    };
  };

  home.sessionVariables = {
    BROWSER = "flatpak run app.zen_browser.zen";
    DEFAULT_BROWSER = "flatpak run app.zen_browser.zen";
  };

  # Helper desktop entry to launch zen via flatpak easily from hyprland bind
  xdg.desktopEntries.zen-browser = {
    name = "Zen Browser";
    exec = "flatpak run app.zen_browser.zen %U";
    comment = "Zen Browser (Flatpak)";
    categories = ["Network" "WebBrowser"];
    mimeType = ["text/html" "x-scheme-handler/http" "x-scheme-handler/https"];
  };
}
