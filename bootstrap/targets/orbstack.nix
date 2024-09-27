{
  config,
  lib,
  modulesPath,
  ...
}:
let
  inherit (builtins) listToAttrs;
  inherit (lib) mkForce mkIf;

  disabledWatchdogs =
    let
      disableWatchdog =
        units:
        listToAttrs (
          map (name: {
            inherit name;
            value = {
              serviceConfig.WatchdogSec = 0;
            };
          }) units
        );
    in
    {
      services = disableWatchdog [
        "systemd-oomd"
        "systemd-userdbd"
        "systemd-udevd"
        "systemd-timesyncd"
        "systemd-timedated"
        "systemd-portabled"
        "systemd-nspawn@"
        "systemd-machined"
        "systemd-localed"
        "systemd-logind"
        "systemd-journald@"
        "systemd-journald"
        "systemd-journal-remote"
        "systemd-journal-upload"
        "systemd-importd"
        "systemd-hostnamed"
        "systemd-homed"
        "systemd-networkd"
      ];
    };
in
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  config = mkIf (config.dusk.target == "orbstack") {
    users = {
      # This being `true` leads to a few nasty bugs, change at your own risk!
      mutableUsers = false;

      users.${config.dusk.username} = {
        uid = 501;
        extraGroups = [ "wheel" ];

        # simulate isNormalUser, but with an arbitrary UID
        isSystemUser = true;
        group = "users";
        createHome = true;
        home = "/home/${config.dusk.username}";
        homeMode = "700";
        useDefaultShell = true;
      };
    };

    security.sudo.wheelNeedsPassword = false;

    systemd = {
      network = {
        enable = true;
        networks."50-eth0" = {
          matchConfig.Name = "eth0";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = true;
          };
          linkConfig.RequiredForOnline = "routable";
        };
      };
    } // disabledWatchdogs;

    # Environment configurations
    environment = {
      shellInit = ''
        . /opt/orbstack-guest/etc/profile-early

        # add your customizations here

        . /opt/orbstack-guest/etc/profile-late
      '';
      etc."resolv.conf".source = "/opt/orbstack-guest/etc/resolv.conf";
    };

    networking = {
      useDHCP = mkForce false;
      useHostResolvConf = mkForce false;

      dhcpcd = {
        enable = mkForce false;
        extraConfig = ''
          noarp
          noipv6
        '';
      };
    };

    services = {
      resolved.enable = mkForce false;
      openssh.enable = mkForce false;
    };

    # Program configurations
    programs.ssh.extraConfig = ''
      Include /opt/orbstack-guest/etc/ssh_config
    '';

    # Nix settings
    nix.settings.extra-platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
}
