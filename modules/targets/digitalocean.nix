{ config, lib, ... }:
{
  config = lib.mkIf (config.dusk.target == "digitalocean") {
    # do not use DHCP, as DigitalOcean provisions IPs using cloud-init
    networking.useDHCP = lib.mkForce false;

    services.cloud-init = {
      enable = true;
      network.enable = true;
    };
  };
}
