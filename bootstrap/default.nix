{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;
  inherit (lib)
    flatten
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
    ./targets
    ./filesystem.nix
  ];

  options.dusk = {
    username = mkOption {
      type = types.str;
      default = "dusk";
      description = "The user to create (used for remote access, as root is disabled).";
    };

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

    target = mkOption {
      type = types.enum [
        "digitalocean"
        "linode"
        "qemu"
        "vultr"
      ];
      description = "The target host configuration to use";
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

        trusted-users = [ cfg.username ];

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
        PermitRootLogin = mkForce "prohibit-password";
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

    users.users = {
      ${cfg.username} = {
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        openssh.authorizedKeys.keys = flatten (attrValues (import ./../keys.nix));
      };

      root.openssh.authorizedKeys.keys = flatten (attrValues (import ./../keys.nix));
    };
  };
}
