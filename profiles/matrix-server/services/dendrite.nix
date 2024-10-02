{
  config,
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

  cfg = config.dusk.dendrite;

  generateConnectionString =
    {
      user,
      password,
      host,
      port,
      name,
      sslMode,
      ...
    }:
    "postgresql://${user}${
      if password != null then ":${password}" else ""
    }@${host}:${toString port}/${name}?sslmode=${sslMode}";
in
{
  options.dusk.dendrite = {
    enable = mkEnableOption "Dendrite Matrix Server";

    user = mkOption {
      type = types.str;
      default = "dendrite";
      description = "The user to run Dendrite as.";
    };

    group = mkOption {
      type = types.str;
      default = "dendrite";
      description = "The group to run Dendrite as.";
    };

    rootDir = mkOption {
      type = types.str;
      default = "/var/lib/dendrite";
      description = "The root directory for Dendrite to run inside.";
    };

    global = {
      serverName = mkOption {
        type = types.str;
        default = "localhost";
        description = "The domain name of this homeserver.";
      };

      privateKey = mkOption {
        type = types.str;
        description = "The path to the signing private key file, used to sign requests and events.";
      };

      oldPrivateKeys = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              privateKey = mkOption {
                type = types.str;
                description = "Path to the old private key file.";
              };

              publicKey = mkOption {
                type = types.str;
                description = "The public key in base64 format.";
              };

              keyId = mkOption {
                type = types.str;
                description = "The key ID.";
              };

              expiredAt = mkOption {
                type = types.int;
                description = "Expiry timestamp in millisecond precision.";
              };
            };
          }
        );
        default = [ ];
        description = "List of old signing keys that were formerly in use on this domain name.";
      };

      keyValidityPeriod = mkOption {
        type = types.str;
        default = "168h0m0s";
        description = "How long a remote server can cache our server signing key before requesting it again.";
      };

      wellKnownServerName = mkOption {
        type = types.str;
        default = "";
        description = "The server name to delegate server-server communications to, with optional port.";
      };

      wellKnownClientName = mkOption {
        type = types.str;
        default = "";
        description = "The base URL to delegate client-server communications to.";
      };

      wellKnownSlidingSyncProxy = mkOption {
        type = types.str;
        default = "";
        description = "The server name to delegate sliding sync communications to, with optional port.";
      };

      trustedThirdPartyIdServers = mkOption {
        type = types.listOf types.str;
        default = [
          "matrix.org"
          "vector.im"
        ];
        description = "Lists of domains that the server will trust as identity servers.";
      };

      disableFederation = mkOption {
        type = types.bool;
        default = false;
        description = "Disables federation. Dendrite will not be able to communicate with other servers in the Matrix federation.";
      };

      presence = {
        enableInbound = mkEnableOption "inbound presence events from other servers";
        enableOutbound = mkEnableOption "outbound presence events for local users to other servers";
      };

      reportStats = {
        enable = mkEnableOption "phone-home statistics reporting";

        endpoint = mkOption {
          type = types.str;
          default = "https://panopticon.matrix.org/push";
          description = "The endpoint to send statistics to.";
        };
      };

      serverNotices = {
        enable = mkEnableOption "server notices";
        localPart = mkOption {
          type = types.str;
          default = "_server";
          description = "The local part for the user that will send server notices.";
        };
        displayName = mkOption {
          type = types.str;
          default = "Server Alerts";
          description = "The display name for the user that will send server notices.";
        };
        avatarUrl = mkOption {
          type = types.str;
          default = "";
          description = "The avatar URL (as a mxc:// URL) for the user that will send server notices.";
        };
        roomName = mkOption {
          type = types.str;
          default = "Server Alerts";
          description = "The room name to be used when sending server notices.";
        };
      };
    };

    database = {
      user = mkOption {
        type = types.str;
        default = "dendrite";
        description = "The database user.";
      };
      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The database password.";
      };
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "The database host.";
      };
      port = mkOption {
        type = types.int;
        default = 5432;
        description = "The database port.";
      };
      name = mkOption {
        type = types.str;
        default = "dendrite";
        description = "The database name.";
      };
      sslMode = mkOption {
        type = types.enum [
          "disable"
          "require"
          "verify-ca"
          "verify-full"
        ];
        default = "disable";
        description = "The SSL mode for the database connection.";
      };
      maxOpenConns = mkOption {
        type = types.int;
        default = 90;
        description = "The maximum number of open connections to the database.";
      };
      maxIdleConns = mkOption {
        type = types.int;
        default = 5;
        description = "The maximum number of connections in the idle connection pool.";
      };
      connMaxLifetime = mkOption {
        type = types.int;
        default = -1;
        description = "The maximum amount of time a connection may be reused.";
      };
    };

    cache = {
      maxSizeEstimated = mkOption {
        type = types.str;
        default = "1gb";
        description = "The estimated maximum size for the global cache.";
      };
      maxAge = mkOption {
        type = types.str;
        default = "1h";
        description = "The maximum amount of time that a cache entry can live for in memory.";
      };
    };

    jetstream = {
      addresses = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "A list of NATS Server addresses to connect to.";
      };
      disableTLSValidation = mkOption {
        type = types.bool;
        default = false;
        description = "Disable the validation of TLS certificates of NATS.";
      };
      storagePath = mkOption {
        type = types.str;
        default = "${cfg.rootDir}/jetstream";
        description = "Persistent directory to store JetStream streams in.";
      };
      topicPrefix = mkOption {
        type = types.str;
        default = "Dendrite";
        description = "The prefix to use for stream names for this homeserver.";
      };
    };

    metrics = {
      enable = mkEnableOption "Prometheus metric collection";
      basicAuth = {
        username = mkOption {
          type = types.str;
          default = "metrics";
          description = "The username for basic auth on the metrics endpoint.";
        };
        password = mkOption {
          type = types.str;
          default = "metrics";
          description = "The password for basic auth on the metrics endpoint.";
        };
      };
    };

    dnsCache = {
      enable = mkEnableOption "the optional DNS cache";
      cacheSize = mkOption {
        type = types.int;
        default = 256;
        description = "The size of the DNS cache.";
      };
      cacheLifetime = mkOption {
        type = types.str;
        default = "5m";
        description = "The lifetime of entries in the DNS cache.";
      };
    };

    appServiceAPI = {
      disableTLSValidation = mkEnableOption "disabling the validation of TLS certificates of appservices";
      legacyAuth = mkEnableOption "sending the access_token query parameter with appservice requests in addition to the Authorization header";
      legacyPaths = mkEnableOption "using the legacy unprefixed paths for appservice requests";
      configFiles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Appservice configuration files to load into this homeserver.";
      };
    };

    clientAPI = {
      registrationDisabled = mkOption {
        type = types.bool;
        default = true;
        description = "Prevents new users from being able to register on this homeserver.";
      };

      guestsDisabled = mkOption {
        type = types.bool;
        default = true;
        description = "Prevents new guest accounts from being created.";
      };

      registrationSharedSecretPath = mkOption {
        type = types.str;
        description = "The path for the shared registration secret for this homeserver.";
      };

      enableRegistrationCaptcha = mkEnableOption "requiring reCAPTCHA for registration";

      recaptchaPublicKey = mkOption {
        type = types.str;
        default = "";
        description = "The public key for ReCAPTCHA.";
      };

      recaptchaPrivateKey = mkOption {
        type = types.str;
        default = "";
        description = "The private key for ReCAPTCHA.";
      };

      recaptchaBypassSecret = mkOption {
        type = types.str;
        default = "";
        description = "The bypass secret for ReCAPTCHA.";
      };

      turn = {
        turnUserLifetime = mkOption {
          type = types.str;
          default = "5m";
          description = "The lifetime of TURN credentials.";
        };
        turnUris = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "TURN server URIs.";
        };
        turnSharedSecret = mkOption {
          type = types.str;
          default = "";
          description = "The shared secret for the TURN server.";
        };
        turnUsername = mkOption {
          type = types.str;
          default = "";
          description = "The static username for the TURN server.";
        };
        turnPassword = mkOption {
          type = types.str;
          default = "";
          description = "The static password for the TURN server.";
        };
      };

      rateLimiting = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enables rate limiting.";
        };

        threshold = mkOption {
          type = types.int;
          default = 20;
          description = "The threshold for rate limiting.";
        };

        cooloffMs = mkOption {
          type = types.int;
          default = 500;
          description = "The cooloff time in milliseconds for rate limiting.";
        };

        exemptUserIds = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "User IDs exempt from rate limiting.";
        };
      };
    };

    federationAPI = {
      sendMaxRetries = mkOption {
        type = types.int;
        default = 16;
        description = "How many times to retry sending a failed transaction to a specific server.";
      };

      disableTLSValidation = mkEnableOption "disabling the validation of TLS certificates of remote federated homeservers";
      disableHTTPKeepalives = mkEnableOption "disabling HTTP keepalives, which also prevents connection reuse";

      keyPerspectives = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              serverName = mkOption {
                type = types.str;
                description = "The name of the perspective server.";
              };
              keys = mkOption {
                type = types.listOf (
                  types.submodule {
                    options = {
                      keyId = mkOption {
                        type = types.str;
                        description = "The ID of the key.";
                      };
                      publicKey = mkOption {
                        type = types.str;
                        description = "The public key.";
                      };
                    };
                  }
                );
                description = "The keys for the perspective server.";
              };
            };
          }
        );
        default = [
          {
            serverName = "matrix.org";
            keys = [
              {
                keyId = "ed25519:auto";
                publicKey = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
              }
              {
                keyId = "ed25519:a_RXGa";
                publicKey = "l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ";
              }
            ];
          }
        ];
        description = "Perspective keyservers to use as a backup when direct key fetches fail.";
      };
      preferDirectFetch = mkEnableOption "preferring to look up keys directly instead of using perspective servers first";
    };

    mediaAPI = {
      basePath = mkOption {
        type = types.str;
        default = "${cfg.rootDir}/media";
        description = "Storage path for uploaded media.";
      };

      maxFileSizeBytes = mkOption {
        type = types.int;
        default = 10485760;
        description = "The maximum allowed file size (in bytes) for media uploads.";
      };

      dynamicThumbnails = mkEnableOption "dynamically generating thumbnails if needed";
      maxThumbnailGenerators = mkOption {
        type = types.int;
        default = 10;
        description = "The maximum number of simultaneous thumbnail generators to run.";
      };
      thumbnailSizes = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              width = mkOption {
                type = types.int;
                description = "The width of the thumbnail.";
              };
              height = mkOption {
                type = types.int;
                description = "The height of the thumbnail.";
              };
              method = mkOption {
                type = types.enum [
                  "crop"
                  "scale"
                ];
                description = "The method to use for creating the thumbnail.";
              };
            };
          }
        );
        default = [
          {
            width = 32;
            height = 32;
            method = "crop";
          }
          {
            width = 96;
            height = 96;
            method = "crop";
          }
          {
            width = 640;
            height = 480;
            method = "scale";
          }
        ];
        description = "A list of thumbnail sizes to be generated for media content.";
      };
    };

    mscs = {
      mscs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of experimental MSCs to enable on this homeserver.";
      };
    };

    syncAPI = {
      realIpHeader = mkOption {
        type = types.str;
        default = "";
        description = "The HTTP header to inspect to find the real remote IP address of the client.";
      };

      search = {
        enable = mkEnableOption "search functionality";

        indexPath = mkOption {
          type = types.str;
          default = "${cfg.rootDir}/search-index";
          description = "The path where the search index will be created.";
        };

        language = mkOption {
          type = types.str;
          default = "en";
          description = "The language most likely to be used on the server - used when indexing.";
        };
      };
    };

    userAPI = {
      bcryptCost = mkOption {
        type = types.int;
        default = 10;
        description = "The cost when hashing passwords on registration/login.";
      };
      openidTokenLifetimeMs = mkOption {
        type = types.int;
        default = 3600000;
        description = "The lifetime of an OpenID token in milliseconds.";
      };
      autoJoinRooms = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Rooms that users will automatically join when they register.";
      };
      workerCount = mkOption {
        type = types.int;
        default = 8;
        description = "The number of workers to start for the DeviceListUpdater.";
      };
    };

    logging = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            type = mkOption {
              type = types.enum [
                "std"
                "file"
              ];
              description = "The type of logging output.";
            };
            level = mkOption {
              type = types.enum [
                "debug"
                "info"
                "warn"
                "error"
              ];
              description = "The log level.";
            };
            params = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Additional parameters for the logger.";
            };
          };
        }
      );
      default = [
        {
          type = "std";
          level = "info";
        }
        {
          type = "file";
          level = "info";
          params = {
            path = "${cfg.rootDir}/logs";
          };
        }
      ];
      description = "Logging configuration.";
    };
  };

  config = mkIf cfg.enable {
    services = {
      dendrite = {
        enable = true;

        environmentFile = pkgs.writeText "dendrite-env.sh" ''
          export DENDRITE_REGISTRATION_SECRET="$(cat ${cfg.clientAPI.registrationSharedSecretPath})"
        '';

        settings = {
          global = {
            server_name = cfg.global.serverName;
            private_key = cfg.global.privateKey;
            old_private_keys = cfg.global.oldPrivateKeys;
            key_validity_period = cfg.global.keyValidityPeriod;
            well_known_server_name = cfg.global.wellKnownServerName;
            well_known_client_name = cfg.global.wellKnownClientName;
            well_known_sliding_sync_proxy = cfg.global.wellKnownSlidingSyncProxy;
            trusted_third_party_id_servers = cfg.global.trustedThirdPartyIdServers;
            disable_federation = cfg.global.disableFederation;
            presence = {
              enable_inbound = cfg.global.presence.enableInbound;
              enable_outbound = cfg.global.presence.enableOutbound;
            };
            report_stats = {
              enabled = cfg.global.reportStats.enable;
              endpoint = cfg.global.reportStats.endpoint;
            };
            server_notices = {
              enabled = cfg.global.serverNotices.enable;
              local_part = cfg.global.serverNotices.localPart;
              display_name = cfg.global.serverNotices.displayName;
              avatar_url = cfg.global.serverNotices.avatarUrl;
              room_name = cfg.global.serverNotices.roomName;
            };
          };

          database = {
            connection_string = generateConnectionString cfg.database;
            max_open_conns = cfg.database.maxOpenConns;
            max_idle_conns = cfg.database.maxIdleConns;
            conn_max_lifetime = cfg.database.connMaxLifetime;
          };

          cache = {
            max_size_estimated = cfg.cache.maxSizeEstimated;
            max_age = cfg.cache.maxAge;
          };

          jetstream = {
            addresses = cfg.jetstream.addresses;
            disable_tls_validation = cfg.jetstream.disableTLSValidation;
            storage_path = cfg.jetstream.storagePath;
            topic_prefix = cfg.jetstream.topicPrefix;
          };

          metrics = {
            enabled = cfg.metrics.enable;
            basic_auth = {
              username = cfg.metrics.basicAuth.username;
              password = cfg.metrics.basicAuth.password;
            };
          };

          dns_cache = {
            enabled = cfg.dnsCache.enable;
            cache_size = cfg.dnsCache.cacheSize;
            cache_lifetime = cfg.dnsCache.cacheLifetime;
          };

          app_service_api = {
            disable_tls_validation = cfg.appServiceAPI.disableTLSValidation;
            legacy_auth = cfg.appServiceAPI.legacyAuth;
            legacy_paths = cfg.appServiceAPI.legacyPaths;
            config_files = cfg.appServiceAPI.configFiles;
          };

          client_api = {
            registration_disabled = cfg.clientAPI.registrationDisabled;
            guests_disabled = cfg.clientAPI.guestsDisabled;
            registration_shared_secret = "$DENDRITE_REGISTRATION_SECRET";
            enable_registration_captcha = cfg.clientAPI.enableRegistrationCaptcha;
            recaptcha_public_key = cfg.clientAPI.recaptchaPublicKey;
            recaptcha_private_key = cfg.clientAPI.recaptchaPrivateKey;
            recaptcha_bypass_secret = cfg.clientAPI.recaptchaBypassSecret;
            turn = {
              turn_user_lifetime = cfg.clientAPI.turn.turnUserLifetime;
              turn_uris = cfg.clientAPI.turn.turnUris;
              turn_shared_secret = cfg.clientAPI.turn.turnSharedSecret;
              turn_username = cfg.clientAPI.turn.turnUsername;
              turn_password = cfg.clientAPI.turn.turnPassword;
            };
            rate_limiting = {
              enabled = cfg.clientAPI.rateLimiting.enable;
              threshold = cfg.clientAPI.rateLimiting.threshold;
              cooloff_ms = cfg.clientAPI.rateLimiting.cooloffMs;
              exempt_user_ids = cfg.clientAPI.rateLimiting.exemptUserIds;
            };
          };

          federation_api = {
            send_max_retries = cfg.federationAPI.sendMaxRetries;
            disable_tls_validation = cfg.federationAPI.disableTLSValidation;
            disable_http_keepalives = cfg.federationAPI.disableHTTPKeepalives;
            key_perspectives = cfg.federationAPI.keyPerspectives;
            prefer_direct_fetch = cfg.federationAPI.preferDirectFetch;
          };

          media_api = {
            base_path = cfg.mediaAPI.basePath;
            max_file_size_bytes = cfg.mediaAPI.maxFileSizeBytes;
            dynamic_thumbnails = cfg.mediaAPI.dynamicThumbnails;
            max_thumbnail_generators = cfg.mediaAPI.maxThumbnailGenerators;
            thumbnail_sizes = cfg.mediaAPI.thumbnailSizes;
          };

          mscs.mscs = cfg.mscs.mscs;

          sync_api = {
            real_ip_header = cfg.syncAPI.realIpHeader;

            search = {
              enabled = cfg.syncAPI.search.enable;
              index_path = cfg.syncAPI.search.indexPath;
              language = cfg.syncAPI.search.language;
            };
          };

          user_api = {
            bcrypt_cost = cfg.userAPI.bcryptCost;
            openid_token_lifetime_ms = cfg.userAPI.openidTokenLifetimeMs;
            auto_join_rooms = cfg.userAPI.autoJoinRooms;
            worker_count = cfg.userAPI.workerCount;
          };

          logging = cfg.logging;
        };
      };

      postgresql = {
        ensureDatabases = [ cfg.database.name ];

        ensureUsers = [
          {
            name = cfg.user;
            ensureDBOwnership = true;
          }
        ];
      };
    };

    systemd = {
      services.dendrite.serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.rootDir;
      };

      tmpfiles.rules = [
        "d ${cfg.jetstream.storagePath} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.mediaAPI.basePath} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.syncAPI.search.indexPath} 0750 ${cfg.user} ${cfg.group} -"
      ];
    };

    users = {
      groups.${cfg.group} = { };

      users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.rootDir;
        createHome = false;
      };
    };
  };
}
