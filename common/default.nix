{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    lowPrio
    mkDefault
    mkForce
    mkOption
    types
    ;
  cfg = config.dusk;
in
{
  imports = [
    ./services
    ./user.nix
  ];

  options.dusk = {
    locale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = "The system locale";
    };

    hostName = mkOption {
      type = types.str;
      default = "ghost";
      description = "The hostName this machine should assume";
    };

    timeZone = mkOption {
      type = types.str;
      default = "UTC";
      description = "The system time zone to use.";
    };
  };

  config = {
    boot.loader.grub = {
      enable = true;
      forceInstall = lib.mkDefault false;

      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        {
          devices = [ "nodev" ];
          path = "/boot";
        }
      ];
    };

    environment = {
      defaultPackages = mkForce [ ];

      etc."nix/inputs/nixpkgs" = mkForce { source = inputs.nixpkgs; };

      systemPackages =
        with pkgs;
        map lowPrio [
          bash
          curl
          gitMinimal
          inetutils
          mtr
          sysstat
        ];
    };

    fileSystems = {
      "/boot" = {
        device = "/dev/disk/by-partlabel/disk-main-ESP";
        fsType = "vfat";
      };

      "/" = {
        device = "/dev/disk/by-partlabel/disk-main-root";
        fsType = "ext4";
      };
    };

    i18n.defaultLocale = cfg.locale;

    i18n.extraLocaleSettings = {
      LC_ADDRESS = cfg.locale;
      LC_IDENTIFICATION = cfg.locale;
      LC_MEASUREMENT = cfg.locale;
      LC_MONETARY = cfg.locale;
      LC_NAME = cfg.locale;
      LC_NUMERIC = cfg.locale;
      LC_PAPER = cfg.locale;
      LC_TELEPHONE = cfg.locale;
      LC_TIME = cfg.locale;
    };

    time = {
      inherit (config.dusk) timeZone;
    };

    networking = {
      inherit (cfg) hostName;
      firewall.enable = false;

      useDHCP = mkDefault true;
      usePredictableInterfaceNames = mkDefault false;
    };

    nix = {
      package = pkgs.nix;

      gc.automatic = true;
      optimise.automatic = true;

      nixPath = mkForce [ "/etc/nix/inputs" ];

      registry.nixpkgs = mkForce { flake = inputs.nixpkgs; };

      settings = {
        accept-flake-config = true;
        allow-import-from-derivation = true;
        auto-optimise-store = true;

        experimental-features = [
          "nix-command"
          "flakes"
        ];

        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      };
    };

    security = {
      audit = {
        enable = mkDefault true;
        rules = [ "-a exit,always -F arch=b64 -S execve" ];
      };

      auditd.enable = mkDefault true;
    };

    services.openssh = {
      enable = true;

      settings = {
        PermitRootLogin = mkForce "no";
        PasswordAuthentication = mkForce false;
        ChallengeResponseAuthentication = mkForce false;
        GSSAPIAuthentication = mkForce false;
        KerberosAuthentication = mkForce false;
        X11Forwarding = mkForce false;
        PermitUserEnvironment = mkForce false;
        AllowAgentForwarding = mkForce false;
        AllowTcpForwarding = mkForce false;
        PermitTunnel = mkForce false;
      };
    };

    system.stateVersion = "24.11";
  };
}
