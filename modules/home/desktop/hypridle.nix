_: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "quickshell --config onix ipc call onixLock lock";
        before_sleep_cmd = "quickshell --config onix ipc call onixLock lock";
        after_sleep_cmd = "niri msg action power-on-monitors";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = "niri msg action power-off-monitors";
          on-resume = "niri msg action power-on-monitors";
        }
      ];
    };
  };
}
