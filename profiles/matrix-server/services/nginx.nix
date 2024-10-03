{
  config,
  dusk,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.dendrite;

  rootConfig = {
    locations = {
      "/.well-known/matrix/server".extraConfig = ''
        default_type application/json;
        return 200 '{ "m.server": "${cfg.global.serverName}:443" }';
        add_header "Access-Control-Allow-Origin" *;
      '';

      "/.well-known/matrix/client".extraConfig = ''
        default_type application/json;
        return 200 '{ "m.homeserver": { "base_url": "https://${cfg.global.serverName}" }, "org.matrix.msc3575.proxy": { "url": "https://${cfg.global.serverName}" } }';
        add_header "Access-Control-Allow-Origin" *;
      '';
    };
  };

  domainConfig =
    overrides:
    {
      extraConfig = ''
        client_max_body_size 30M;

        proxy_read_timeout 600;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';

      locations = {
        # sliding sync
        "~ ^/(client/|_matrix/client/unstable/org.matrix.msc3575/sync)" = {
          proxyPass = "http://${config.services.matrix-sliding-sync.settings.SYNCV3_BINDADDR}";
        };

        "/_matrix".proxyPass = "http://127.0.0.1:${toString config.services.dendrite.httpPort}";
        "/_dendrite".proxyPass = "http://127.0.0.1:${toString config.services.dendrite.httpPort}";

        # for remote admin access
        "/_synapse".proxyPass = "http://127.0.0.1:${toString config.services.dendrite.httpPort}";
      };
    }
    // overrides;
in
{
  config = mkIf cfg.enable {
    security.acme.certs.${cfg.global.serverName}.email = dusk.email;

    services.nginx.virtualHosts = {
      ${dusk.domain} = rootConfig;
      ${dusk.tor.domain} = rootConfig;

      "matrix.${dusk.domain}" = domainConfig {
        enableACME = true;
        forceSSL = true;
      };

      "matrix.${dusk.tor.domain}" = domainConfig {
        enableACME = false;
        forceSSL = false;
      };
    };
  };
}
