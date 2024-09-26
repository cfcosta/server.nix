{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (config.dusk.target == "vultr") {
    boot.loader.grub = {
      devices = [ "/dev/vda" ];
      forceInstall = true;
    };

    dusk.disks.main.device = "/dev/vda";
    networking.networkmanager.enable = true;
  };
}
