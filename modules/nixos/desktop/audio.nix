{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.desktop.audio;
in {
  options.onix.desktop.audio.enable = mkEnableOption "PipeWire audio";

  config = mkIf cfg.enable {
    services.pulseaudio.enable = mkForce false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
      wireplumber.enable = true;
    };
  };
}
