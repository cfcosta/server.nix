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
    vendorHash = "sha256-Q+UGrk308O114TpSttJTIfi2itx8OiINGCGI4P4RtVQ=";
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
        --set FETCH_SYNC "${if cfg.fetchSync then "TRUE" else "FALSE"}" \
        --set BLOSSOM_ASSETS_PATH "${cfg.blossomAssetsPath}" \
        --set BLOSSOM_PUBLIC_URL "http://${config.dusk.satellite-cdn.cdnEndpoint}"
    '';
  };
in
{
  options.dusk.chronicle = {
    enable = mkEnableOption "Enable Chronicle Nostr Relay";

    ownerPubkey = mkOption {
      description = "pubkey for the owner of this Nostr Relay";
      type = types.str;
    };

    name = mkOption {
      description = "name of the Nostr Relay";
      type = types.str;
    };

    description = mkOption {
      description = "description of the Nostr Relay";
      type = types.str;
    };

    url = mkOption {
      description = "URL of the Nostr Relay";
      type = types.str;
      default = "nostr.${dusk.domain}";
    };

    torUrl = mkOption {
      description = "URL of the Nostr Relay in the Onion Network";
      type = types.str;
      default = "nostr.${dusk.tor.domain}";
    };

    port = mkOption {
      description = "port of the Nostr Relay";
      type = types.int;
      default = 8080;
    };

    icon = mkOption {
      description = "icon URL of the Nostr Relay";
      type = types.str;
    };

    contact = mkOption {
      description = "contact information for the Nostr Relay";
      type = types.str;
    };

    rootDir = mkOption {
      description = "path for all Nostr relay configuration";
      type = types.str;
      default = "/var/lib/chronicle";
    };

    dbPath = mkOption {
      description = "path to the database directory";
      type = types.str;
      default = "${cfg.rootDir}/db";
    };

    blossomAssetsPath = mkOption {
      description = "location to save downloaded Blossom media";
      type = types.str;
      default = "${cfg.rootDir}/blossom";
    };

    refreshInterval = mkOption {
      description = "refresh interval for the Nostr Relay";
      type = types.int;
      default = 24;
    };

    minFollowers = mkOption {
      description = "minimum number of followers for the Nostr Relay";
      type = types.int;
      default = 3;
    };

    fetchSync = mkOption {
      description = "whether or not to allow the Nostr Relay to fetch old notes";
      type = types.bool;
      default = true;
    };

    user = mkOption {
      description = "user to run the Nostr Relay service";
      type = types.str;
      default = "chronicle";
    };

    group = mkOption {
      description = "group to run the Nostr Relay service";
      type = types.str;
      default = "chronicle";
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs.${cfg.url}.email = dusk.email;

    services = {
      nginx = {
        virtualHosts = {
          ${cfg.url} = {
            enableACME = true;
            forceSSL = true;

            locations = {
              "/" = {
                extraConfig = optionalString config.services.tor.enable ''
                  add_header Onion-Location http://${cfg.torUrl}$request_uri;
                '';

                proxyPass = "http://127.0.0.1:${toString cfg.port}";
                proxyWebsockets = true;
              };
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
    };

    users = {
      users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.rootDir;
        createHome = true;
      };

      groups.${cfg.group} = { };
    };
  };
}
