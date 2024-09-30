{
  config,
  dusk,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.dendrite;
in
{
  config = mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;

      certs = {
        ${dusk.domain}.email = dusk.domainOwner;
        ${cfg.global.serverName}.email = dusk.domainOnwer;
      };
    };

    services.nginx = {
      enable = true;

      virtualHosts = {
        ${dusk.domain} = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/.well-known/matrix/server".extraConfig = ''
              default_type application/json;
              return 200 '{ "m.server": "${cfg.global.serverName}:443" }';
            '';

            "/.well-known/matrix/client".extraConfig = ''
              default_type application/json;
              return 200 '{ "m.homeserver": { "base_url": "https://${cfg.global.serverName}" } }';
              add_header "Access-Control-Allow-Origin" *;
            '';
          };
        };

        ${cfg.global.serverName} = {
          enableACME = true;
          forceSSL = true;

          locations."/_matrix" = {
            proxyPass = "http://127.0.0.1:8008";
          };
        };
      };
    };
  };
}
