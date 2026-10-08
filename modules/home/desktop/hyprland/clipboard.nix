{pkgs, ...}: {
  # Clipboard history daemon: keeps text + images offered to cliphist.
  # Picker lives on SUPER+SHIFT+V (see binds.nix).
  systemd.user.services = {
    cliphist-text = {
      Unit.Description = "cliphist text clipboard watcher";
      Service.ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      Install.WantedBy = ["hyprland-session.target"];
    };
    cliphist-image = {
      Unit.Description = "cliphist image clipboard watcher";
      Service.ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
      Install.WantedBy = ["hyprland-session.target"];
    };
  };
}
