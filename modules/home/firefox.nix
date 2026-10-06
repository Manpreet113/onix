{ config, pkgs, ... }: {
  programs.firefox = {
    enable = true;
    # Keep system firefox enabled too? HM firefox will be user-level.
    # We disable HM firefox if you prefer system-only; but HM allows profiles.
    # Enable as user package; system firefox remains for completeness.
    # To avoid duplication, we let system handle it: comment enable if not desired.
    # Currently enabled for HM profiles:
    profiles.manpreet = {
      isDefault = true;
      settings = {
        "browser.startup.homepage" = "https://search.nixos.org";
        "browser.search.defaultenginename" = "DuckDuckGo";
        "browser.search.order.1" = "DuckDuckGo";
        "signon.rememberSignons" = false;
        "browser.newtabpage.enabled" = false;
        "trailhead.firstrun.didSeeAboutWelcome" = true;
      };
      # extensions handled separately; add NUR if you add nur input
      extensions.packages = with pkgs; [
        # e.g. firefoxAddons.ublock-origin if available
      ];
    };
  };
}
