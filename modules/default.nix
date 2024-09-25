{ lib, pkgs, ... }:
let
  inherit (lib) lowPrio;
in
{
  imports = [
    ./common
    ./targets
  ];

  config = {
    boot.loader.grub = {
      enable = true;

      zfsSupport = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        {
          devices = [ "nodev" ];
          path = "/boot";
        }
      ];
    };

    services.openssh.enable = true;

    environment.systemPackages =
      with pkgs;
      map lowPrio [
        curl
        gitMinimal
      ];

    users.users.root.openssh.authorizedKeys.keys = [
      # TODO: change this to your ssh key
      "CHANGE"
    ];

    system.stateVersion = "24.11";
  };
}
