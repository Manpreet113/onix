{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.onix.networking;
in {
  options.onix.networking.enable = mkEnableOption "NetworkManager networking";

  config = mkIf cfg.enable {
    networking.networkmanager.enable = true;

    # Firewall — keep enabled but open nothing by default
    networking.firewall.enable = true;

    # Hostname set in hosts/onix/default.nix
    # Optional: enable mDNS, etc.
    services.resolved.enable = true;
  };
}
