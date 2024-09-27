{
  dusk,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (dusk.target == "vultr") {
    boot.loader.grub = {
      devices = [ "/dev/vda" ];
      forceInstall = true;
    };

    dusk.disks.main.device = "/dev/vda";
  };
}
