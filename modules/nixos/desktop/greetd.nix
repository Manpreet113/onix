{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.desktop.greetd;

  greeterShare = pkgs.runCommand "onix-greeter-assets" {} ''
    mkdir -p $out
    cp -r ${./greeter}/* $out/
  '';

  quickshellWithMedia = pkgs.quickshell.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [pkgs.qt6.qtmultimedia];
  });

  cageWithTap = pkgs.cage.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [pkgs.libinput];
    postPatch =
      (old.postPatch or "")
      + ''
        sed -i "/math           = cc.find_library/a libinput_dep   = dependency('libinput')" meson.build
        sed -i '/math,/a \    libinput_dep,' meson.build
        sed -i '/#include <wlr\/util\/log.h>/a #include <wlr/backend/libinput.h>\n#include <libinput.h>' seat.c
        sed -i '/map_input_device_to_output(seat, &wlr_pointer->base, wlr_pointer->output_name);/a \
	if (wlr_input_device_is_libinput(&wlr_pointer->base)) {\
		struct libinput_device *dev = wlr_libinput_get_device_handle(&wlr_pointer->base);\
		if (libinput_device_config_tap_get_finger_count(dev) > 0) {\
			libinput_device_config_tap_set_enabled(dev, LIBINPUT_CONFIG_TAP_ENABLED);\
			libinput_device_config_tap_set_drag_enabled(dev, LIBINPUT_CONFIG_DRAG_ENABLED);\
		}\
		if (libinput_device_config_scroll_has_natural_scroll(dev)) {\
			libinput_device_config_scroll_set_natural_scroll_enabled(dev, 1);\
		}\
	}' seat.c
      '';
  });

  onix-session-hyprland = pkgs.writeShellScriptBin "onix-session-hyprland" ''
    # Clear console and scrollback, keep cursor hidden for completely seamless handoff
    printf "\033[?25l\033[2J\033[3J\033[H"
    printf "\033[?25l\033[2J\033[3J\033[H" > /dev/tty1 2>/dev/null || true

    mkdir -p "$HOME/.local/state/hypr"
    exec > "$HOME/.local/state/hypr/hyprland-session.log" 2>&1

    exec start-hyprland
  '';

  onix-greeter = pkgs.writeShellScriptBin "onix-greeter" ''
    # Clear console, scrollback, and hide cursor on the VT before anything else
    printf "\033[?25l\033[2J\033[3J\033[H"
    printf "\033[?25l\033[2J\033[3J\033[H" > /dev/tty1 2>/dev/null || true

    # Redirect ALL stdout & stderr of onix-greeter to /tmp/onix-greeter.log so VT1 stays completely clean
    exec > /tmp/onix-greeter.log 2>&1

    export PATH="/run/current-system/sw/bin:${pkgs.systemd}/bin:''${PATH:-}"
    export HOME="/tmp/greeter-home"
    export XDG_CACHE_HOME="/tmp/greeter-cache"
    export XDG_CONFIG_HOME="/tmp/greeter-config"
    export XDG_DATA_HOME="/tmp/greeter-data"
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"

    # Match system cursor theme (Bibata-Modern-Classic 24)
    export XCURSOR_THEME="Bibata-Modern-Classic"
    export XCURSOR_SIZE="24"
    export XCURSOR_PATH="${pkgs.bibata-cursors}/share/icons"
    export XDG_DATA_DIRS="${pkgs.bibata-cursors}/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"
    mkdir -p "$XDG_DATA_HOME/icons/default"
    cat <<'EOF' > "$XDG_DATA_HOME/icons/default/index.theme"
[Icon Theme]
Inherits=Bibata-Modern-Classic
EOF

    export QML2_IMPORT_PATH="${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qtwayland}/lib/qt-6/qml:${quickshellWithMedia}/lib/qt-6/qml:''${QML2_IMPORT_PATH:-}"
    export NIXPKGS_QT6_QML_IMPORT_PATH="${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qtwayland}/lib/qt-6/qml:${quickshellWithMedia}/lib/qt-6/qml:''${NIXPKGS_QT6_QML_IMPORT_PATH:-}"
    export QT_PLUGIN_PATH="${pkgs.qt6.qtmultimedia}/lib/qt-6/plugins:${pkgs.qt6.qtbase}/lib/qt-6/plugins:${pkgs.qt6.qtsvg}/lib/qt-6/plugins:''${QT_PLUGIN_PATH:-}"
    export GST_PLUGIN_SYSTEM_PATH_1_0="${pkgs.gst_all_1.gstreamer}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-libav}/lib/gstreamer-1.0"

    exec ${cageWithTap}/bin/cage -s -d -- \
      ${quickshellWithMedia}/bin/quickshell -p "${greeterShare}/shell.qml" "$@"
  '';
in {
  options.onix.desktop.greetd.enable = mkEnableOption "Onix Quickshell display manager via greetd";

  config = mkIf cfg.enable {
    # Ensure greeter user has hardware access to DRM/KMS and input devices
    users.users.greeter.extraGroups = ["video" "input"];

    # Allow greeter user to perform power actions via logind/systemd without auth prompts
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.user === "greeter" &&
            (action.id === "org.freedesktop.login1.power-off" ||
             action.id === "org.freedesktop.login1.power-off-multiple-sessions" ||
             action.id === "org.freedesktop.login1.reboot" ||
             action.id === "org.freedesktop.login1.reboot-multiple-sessions" ||
             action.id === "org.freedesktop.login1.suspend" ||
             action.id === "org.freedesktop.login1.suspend-multiple-sessions" ||
             action.id === "org.freedesktop.login1.hibernate" ||
             action.id === "org.freedesktop.login1.hibernate-multiple-sessions")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Silence getty on tty1 so no text cursor or login prompt interferes
    systemd.services."autovt@tty1".enable = false;
    systemd.services."getty@tty1".enable = false;

    # Shared cache directory so user wallpaper and skein theme automatically mirror to greeter
    systemd.tmpfiles.rules = [
      "d /var/cache/onix 0777 root root - -"
    ];

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${onix-greeter}/bin/onix-greeter";
          user = "greeter";
        };
      };
    };

    environment.systemPackages = [
      onix-greeter
      onix-session-hyprland
      cageWithTap
      pkgs.bibata-cursors
    ];

    # Disable GDM/GNOME if previously enabled — ensure no conflict
    services.displayManager.gdm.enable = mkForce false;
    services.desktopManager.gnome.enable = mkForce false;
  };
}
