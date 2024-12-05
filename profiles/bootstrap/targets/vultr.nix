{
  lib,
  target,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (target == "vultr") {
    boot.loader.grub = {
      devices = [ "/dev/vda" ];
      forceInstall = true;
    };

    dusk.disks.main.device = "/dev/vda";
  };
}
