{ lib, pkgs, ... }:
let
  inherit (builtins) attrValues;
  inherit (lib) flatten lowPrio;
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

    users.users.root.openssh.authorizedKeys.keys = flatten (attrValues (import ./../keys.nix));

    system.stateVersion = "24.11";
  };
}
