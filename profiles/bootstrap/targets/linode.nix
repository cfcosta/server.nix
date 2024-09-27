{
  dusk,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (dusk.target == "linode") {
    boot = {
      kernelParams = [ "console=ttyS0,19200n8" ];

      loader.grub = {
        device = "nodev";
        forceInstall = true;

        extraConfig = ''
          serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
          terminal_input serial;
          terminal_output serial
        '';
      };
    };

    dusk.disks.main.device = "/dev/sda";

    networking = {
      interfaces.eth0.useDHCP = true;

      useDHCP = false;
      usePredictableInterfaceNames = false;
    };
  };
}
