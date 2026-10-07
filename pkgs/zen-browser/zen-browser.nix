# Zen Browser, wrapped: nixpkgs wrapFirefox over our unwrapped tarball build.
# Mirrors youwen5/zen-browser-flake (firefoxVersion override for the FFmpeg ABI)
# plus PWA support: firefoxpwa native host + force-installed connector
# extension, so webapps work on Gecko without Chromium.
{
  wrapFirefox,
  zen-browser-unwrapped,
  firefoxpwa,
  ...
}: let
  # wrapFirefox selects the FFmpeg ABI from browser.version. Zen's package
  # version is independent from the underlying Firefox version, so present the
  # Firefox base version to the wrapper while retaining Zen's version on the
  # resulting package.
  browserForWrapper = zen-browser-unwrapped // {version = zen-browser-unwrapped.firefoxVersion;};
in
  wrapFirefox browserForWrapper {
    pname = "zen-browser";
    inherit (zen-browser-unwrapped) version;
    wmClass = "zen";
    icon = "zen";
    nativeMessagingHosts = [firefoxpwa];
    extraPolicies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      ExtensionSettings = {
        # PWA for Firefox connector — declarative webapps on Gecko
        "firefoxpwa@filips.si" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/pwas-for-firefox/latest.xpi";
          installation_mode = "normal_installed";
        };
      };
    };
  }
