{
  lib,
  modulesPath,
  target,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  config = lib.mkIf (target == "qemu") {
    dusk.disks.main.device = "/dev/vda";
  };
}
