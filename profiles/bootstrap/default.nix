{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.dusk;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ../common
    ./targets
  ];

  options.dusk.disks.main.device = mkOption {
    type = types.str;
    description = "The main disk of this system, where the root OS is going to be installed.";
  };

  config = {
    disko.devices.disk = {
      main = {
        inherit (cfg.disks.main) device;

        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
