{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  chronicle = pkgs.buildGo123Module {
    pname = "chronicle";
    version = inputs.chronicle.shortRev;
    src = inputs.chronicle;
    vendorHash = "sha256-6vzytQ4e+ECMGZMUpo9EPdI8Bw0W81+aVdqqYRohHJU=";
  };

  wrappedChronicle = pkgs.symlinkJoin {
    name = "wrapped-chronicle";
    paths = [ chronicle ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/chronicle \
        --set DB_PATH "${config.dusk.chronicle.rootDir}/db" \
        --set OWNER_PUBKEY "${config.dusk.chronicle.ownerPubkey}" \
        --set RELAY_NAME "${config.dusk.chronicle.name}" \
        --set RELAY_DESCRIPTION "${config.dusk.chronicle.description}" \
        --set RELAY_URL "${config.dusk.chronicle.url}" \
        --set RELAY_PORT "${toString config.dusk.chronicle.port}" \
        --set RELAY_ICON "${config.dusk.chronicle.icon}" \
        --set RELAY_CONTACT "${config.dusk.chronicle.contact}" \
        --set REFRESH_INTERVAL "${toString config.dusk.chronicle.refreshInterval}" \
        --set MIN_FOLLOWERS "${toString config.dusk.chronicle.minFollowers}" \
        --set FETCH_SYNC "${if config.dusk.chronicle.fetchSync then "TRUE" else "FALSE"}"
    '';
  };
in
{
  options.dusk.chronicle = {
    enable = mkEnableOption "Enable the Chronicle Nostr Relay";

    ownerPubkey = mkOption {
      description = "The pubkey for the owner of this Nostr Relay.";
      type = types.str;
    };

    name = mkOption {
      description = "The name of the Nostr Relay.";
      type = types.str;
    };

    description = mkOption {
      description = "The description of the Nostr Relay.";
      type = types.str;
    };

    url = mkOption {
      description = "The URL of the Nostr Relay.";
      type = types.str;
      default = "localhost";
    };

    port = mkOption {
      description = "The port of the Nostr Relay.";
      type = types.int;
      default = 8080;
    };

    icon = mkOption {
      description = "The icon URL of the Nostr Relay.";
      type = types.str;
    };

    contact = mkOption {
      description = "The contact information for the Nostr Relay.";
      type = types.str;
    };

    rootDir = mkOption {
      description = "The path for all Nostr relay configuration";
      type = types.str;
      default = "/var/lib/chronicle";
    };

    refreshInterval = mkOption {
      description = "The refresh interval for the Nostr Relay.";
      type = types.int;
      default = 24;
    };

    minFollowers = mkOption {
      description = "The minimum number of followers for the Nostr Relay.";
      type = types.int;
      default = 3;
    };

    fetchSync = mkOption {
      description = "Whether or not to allow the Nostr Relay to fetch old notes.";
      type = types.bool;
      default = true;
    };

    user = mkOption {
      description = "The user to run the Nostr Relay service.";
      type = types.str;
      default = "chronicle";
    };

    group = mkOption {
      description = "The group to run the Nostr Relay service.";
      type = types.str;
      default = "chronicle";
    };
  };

  config = mkIf config.dusk.chronicle.enable {
    systemd.services.chronicle = {
      description = "Chronicle Nostr Relay";

      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${wrappedChronicle}/bin/chronicle";
        Restart = "always";
        User = config.dusk.chronicle.user;
        Group = config.dusk.chronicle.group;
        WorkingDirectory = config.dusk.chronicle.rootDir;
      };
    };

    users = {
      users.${config.dusk.chronicle.user} = {
        isSystemUser = true;
        group = config.dusk.chronicle.group;
        home = config.dusk.chronicle.rootDir;
        createHome = true;
      };

      groups.${config.dusk.chronicle.group} = { };
    };

    networking.firewall.allowedTCPPorts = [ config.dusk.chronicle.port ];
  };
}
