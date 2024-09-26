{
  config,
  lib,
  modulesPath,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkForce
    mkIf
    mkOverride
    ;
in
{
  imports = [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
  ];

  config = mkIf (config.dusk.target == "digitalocean") {
    boot.loader = {
      grub.enable = mkForce false;
      systemd-boot.enable = true;
    };

    dusk.disks.main.device = "/dev/vda";

    networking = {
      # Delegate the hostname setting to cloud-init by default
      hostName = mkOverride 1337 "";

      useDHCP = mkDefault false;
      useNetworkd = mkDefault false;
    };

    services.cloud-init = {
      enable = true;
      network.enable = true;
      settings = {
        datasource_list = [ "DigitalOcean" ];
        datasource.DigitalOcean = { };

        users = [
          "root"
          config.dusk.username
        ];
      };
    };

    virtualisation.digitalOcean = {
      setRootPassword = false;
      setSshKeys = false;
      rebuildFromUserData = false;
    };
  };
}
