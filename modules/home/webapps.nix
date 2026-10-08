# Declarative Chromium webapps on helium (`helium --app=<url>`).
# Zen stays the default browser; webapps are for sites that need Chromium.
# To add one:
#   onix.webapps.<id> = {
#     displayName = "Name";
#     url = "https://…";
#     iconUrl = "https://…svg";                    # optional…
#     iconSha256 = "sha256-…";                     # …but both or neither
#     categories = ["Network" "Chat"];             # optional
#   };
# Icon resolution: iconUrl+iconSha256 (pinned fetch) > icon (theme name
# or absolute path, default "helium"). Get the hash with:
#   nix store prefetch-file <iconUrl>
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.webapps;
  appType = types.submodule ({name, ...}: {
    options = {
      displayName = mkOption {
        type = types.str;
        default = name;
        description = "Display name for the launcher entry.";
      };
      url = mkOption {
        type = types.str;
        description = "URL opened in a helium app window.";
      };
      comment = mkOption {
        type = types.str;
        default = "";
        description = "Tooltip comment for the launcher entry.";
      };
      icon = mkOption {
        type = types.str;
        default = "helium";
        description = "Icon theme name or absolute path. Ignored when iconUrl is set.";
      };
      iconUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Pinned icon URL (e.g. dashboard-icons). Requires iconSha256.";
      };
      iconSha256 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "SRI hash for iconUrl from `nix store prefetch-file`.";
      };
      categories = mkOption {
        type = types.listOf types.str;
        default = ["Network"];
        description = "Desktop entry categories.";
      };
    };
  });
  resolveIcon = app:
    if app.iconUrl != null
    then
      assert lib.assertMsg (app.iconSha256 != null) "onix.webapps: iconSha256 required with iconUrl";
      "${pkgs.fetchurl {
        url = app.iconUrl;
        sha256 = app.iconSha256;
      }}"
    else app.icon;
in {
  options.onix.webapps = mkOption {
    type = types.attrsOf appType;
    default = {};
    description = "Webapps launched as helium app windows.";
  };

  config = mkIf (cfg != {}) {
    xdg.desktopEntries = mapAttrs (_: app: {
      name = app.displayName;
      exec = "helium --app=${app.url}";
      comment =
        if app.comment != ""
        then app.comment
        else "${app.displayName} Web (Helium app window)";
      icon = resolveIcon app;
      inherit (app) categories;
      startupNotify = true;
    }) cfg;
  };
}
