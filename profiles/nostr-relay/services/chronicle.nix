{
  config,
  dusk,
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
    optionalString
    types
    ;

  cfg = config.dusk.chronicle;

  chronicle = pkgs.buildGo123Module {
    pname = "chronicle-unwrapped";
    version = inputs.chronicle.shortRev;
    src = inputs.chronicle;
    vendorHash = "sha256-6vzytQ4e+ECMGZMUpo9EPdI8Bw0W81+aVdqqYRohHJU=";
  };

  service = pkgs.symlinkJoin {
    name = "chronicle";
    paths = [ chronicle ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/chronicle \
        --set DB_PATH "${cfg.rootDir}/db" \
        --set OWNER_PUBKEY "${cfg.ownerPubkey}" \
        --set RELAY_NAME "${cfg.name}" \
        --set RELAY_DESCRIPTION "${cfg.description}" \
        --set RELAY_URL "${cfg.url}" \
        --set RELAY_PORT "${toString cfg.port}" \
        --set RELAY_ICON "${cfg.icon}" \
        --set RELAY_CONTACT "${cfg.contact}" \
        --set REFRESH_INTERVAL "${toString cfg.refreshInterval}" \
        --set MIN_FOLLOWERS "${toString cfg.minFollowers}" \
        --set FETCH_SYNC "${if cfg.fetchSync then "TRUE" else "FALSE"}"
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
      default = "nostr.${dusk.domain}";
    };

    torUrl = mkOption {
      description = "The URL of the Nostr Relay in the Onion Network.";
      type = types.str;
      default = "nostr.${dusk.tor.domain}";
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

  config = mkIf cfg.enable {
    security.acme.certs.${cfg.url}.email = dusk.domainOwner;

    services = {
      nginx = {
        virtualHosts = {
          ${cfg.url} = {
            enableACME = true;
            forceSSL = true;

            locations."/" = {
              extraConfig = optionalString config.services.tor.enable ''
                add_header Onion-Location http://${cfg.torUrl}$request_uri;
              '';

              proxyPass = "http://127.0.0.1:${toString cfg.port}";
              proxyWebsockets = true;
            };
          };

          ${cfg.torUrl} = {
            enableACME = false;
            forceSSL = false;

            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.port}";
              proxyWebsockets = true;
            };
          };
        };
      };
    };

    systemd = {
      services.chronicle = {
        description = "Chronicle Nostr Relay";

        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${service}/bin/chronicle";
          Restart = "always";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.rootDir;
        };
      };

      tmpfiles.rules = [
        "d ${cfg.rootDir} 0750 ${cfg.user} ${cfg.group} -"
      ];
    };

    users = {
      users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.rootDir;
        createHome = false;
      };

      groups.${cfg.group} = { };
    };
  };
}
