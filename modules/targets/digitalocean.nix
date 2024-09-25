{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkForce mkIf;
  cfg = config.Server.targets.digitalOcean;
in
{
  options.Server.targets.digitalOcean.enable = mkEnableOption "Host configuration for DigitalOcean nodes";

  config = mkIf cfg.enable {
    # do not use DHCP, as DigitalOcean provisions IPs using cloud-init
    networking.useDHCP = mkForce false;

    services.cloud-init = {
      enable = true;
      network.enable = true;
    };
  };
}
