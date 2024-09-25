{ lib, pkgs, ... }:
let
  inherit (lib) lowPrio;
in
{
  imports = [
    ./filesystem.nix
  ];

  config = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
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
