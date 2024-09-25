{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.dusk;
in
{
  options.dusk.disks.main.device = mkOption {
    type = types.str;
    description = "The main disk of this system, where the root OS is going to be installed.";
  };

  config = {
    disko.devices = {
      disk = {
        main = {
          inherit (cfg.disks.main) device;

          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "zroot";
                };
              };
            };
          };
        };
      };
      zpool = {
        zroot = {
          type = "zpool";
          rootFsOptions = {
            acltype = "posixacl";
            atime = "off";
            compression = "zstd";
            mountpoint = "none";
            xattr = "sa";
          };
          options.ashift = "12";

          datasets = {
            "local" = {
              type = "zfs_fs";
              options.mountpoint = "none";
            };
            "local/home" = {
              type = "zfs_fs";
              mountpoint = "/home";
              # Used by services.zfs.autoSnapshot options.
              options."com.sun:auto-snapshot" = "true";
            };
            "local/nix" = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options."com.sun:auto-snapshot" = "false";
            };
            "local/persist" = {
              type = "zfs_fs";
              mountpoint = "/persist";
              options."com.sun:auto-snapshot" = "false";
            };
            "local/root" = {
              type = "zfs_fs";
              mountpoint = "/";
              options."com.sun:auto-snapshot" = "false";
              postCreateHook = "zfs snapshot zroot/local/root@blank";
            };
          };
        };
      };
    };

    services.zfs = {
      autoScrub.enable = true;
      autoSnapshot.enable = true;
    };
  };
}
