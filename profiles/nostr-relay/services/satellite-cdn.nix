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

  cfg = config.dusk.satellite-cdn;

  runtimeEnvFile = "/run/satellite-cdn/env";

  satellite-cdn = pkgs.buildNpmPackage {
    pname = "satellite-cdn";
    version = "1.0.0";
    src = inputs.satellite-cdn;
    npmDepsHash = "sha256-Q07PVrEhZW7BFrZRGkpPE4UgFa2zYOMl/3WxMTmo2Wg=";
    dontNpmBuild = true;
  };

  envFile = pkgs.writeText "satellite-cdn-env-template" ''
    DB_PATH=${cfg.dbPath}
    S3_BUCKET=${cfg.s3Bucket}
    S3_ACCESS_KEY_ID=@r2-access-key@
    S3_SECRET_ACCESS_KEY=@r2-secret-key@
    CF_ACCOUNT_ID=${cfg.cfAccountId}
    APP_SECRET_KEY=@app-secret@
    STORAGE_RATE_USD=${toString cfg.storageRateUsd}
    LIGHTNING_PROVIDER_PUBKEY=${cfg.lightningProviderPubkey}
    LIGHTNING_CALLBACK_URL=${cfg.lightningCallbackUrl}
    CDN_ENDPOINT=${cfg.cdnEndpoint}
    BLOB_ENDPOINT=${cfg.blobEndpoint}
    LISTENER_RELAYS=${lib.concatStringsSep "," cfg.listenerRelays}
  '';
in
{
  options.dusk.satellite-cdn = {
    enable = mkEnableOption "Enable Satellite CDN";

    dbPath = mkOption {
      description = "Path to the SQLite database directory";
      type = types.str;
      default = "/var/lib/satellite-cdn/db";
    };

    s3Bucket = mkOption {
      description = "Name of the R2 bucket";
      type = types.str;
    };

    s3AccessKeyId = mkOption {
      description = "Path to Cloudflare R2 access key ID secret";
      type = types.path;
    };

    s3SecretAccessKey = mkOption {
      description = "Path to Cloudflare R2 secret access key secret";
      type = types.path;
    };

    cfAccountId = mkOption {
      description = "Cloudflare account ID";
      type = types.str;
    };

    appSecretKey = mkOption {
      description = "Path to application secret key secret";
      type = types.path;
    };

    storageRateUsd = mkOption {
      description = "Storage rate in cents per gigabyte per month";
      type = types.int;
      default = 5; # 5 cents
    };

    lightningProviderPubkey = mkOption {
      description = "Lightning provider pubkey";
      type = types.str;
    };

    lightningCallbackUrl = mkOption {
      description = "Lightning callback URL";
      type = types.str;
    };

    cdnEndpoint = mkOption {
      description = "Base URL endpoint of the CDN";
      type = types.str;
    };

    blobEndpoint = mkOption {
      description = "Base URL endpoint for blob storage";
      type = types.str;
    };

    listenerRelays = mkOption {
      description = "List of nostr relays to listen to";
      type = types.listOf types.str;
      default = [
        "wss://relay.damus.io"
        "wss://nos.lol"
        "wss://relay.snort.social"
        "wss://relay.nostrplebs.com"
        "wss://relay.plebstr.com"
        "wss://relay.nostr.band"
        "wss://nostr.wine"
      ];
    };

    port = mkOption {
      description = "Port for the Satellite CDN service";
      type = types.int;
      default = 5050;
    };

    user = mkOption {
      description = "User to run the Satellite CDN service";
      type = types.str;
      default = "satellite-cdn";
    };

    group = mkOption {
      description = "Group to run the Satellite CDN service";
      type = types.str;
      default = "satellite-cdn";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts."satellite-cdn-env" = ''
      mkdir -p "$(dirname ${runtimeEnvFile})"
      cp ${envFile} ${runtimeEnvFile}

      r2_access_key=$(cat "${cfg.s3AccessKeyId}")
      r2_secret_key=$(cat "${cfg.s3SecretAccessKey}")
      app_secret=$(cat "${cfg.appSecretKey}")

      ${pkgs.gnused}/bin/sed -i \
        -e "s#@r2-access-key@#$r2_access_key#" \
        -e "s#@r2-secret-key@#$r2_secret_key#" \
        -e "s#@app-secret@#$app_secret#" \
        "${runtimeEnvFile}"
        
      chmod 600 ${runtimeEnvFile}
      chown ${cfg.user}:${cfg.group} ${runtimeEnvFile}
    '';

    services.nginx.virtualHosts.${cfg.cdnEndpoint} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.port}";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 100M;
        '';
      };
    };

    systemd.services.satellite-cdn = {
      description = "Satellite CDN Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.nodejs}/bin/node ${satellite-cdn}/lib/node_modules/satellite-cdn/index.js";
        EnvironmentFile = "${runtimeEnvFile}";
        Restart = "always";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dbPath;
      };
    };

    users = {
      users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dbPath;
        createHome = true;
      };

      groups.${cfg.group} = { };
    };
  };
}
