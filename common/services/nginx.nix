{
  config,
  dusk,
  lib,
  ...
}:
{
  config = {
    security.acme = {
      acceptTerms = true;
      certs.${dusk.domain}.email = dusk.email;
    };

    services.nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      serverNamesHashBucketSize = 128;

      virtualHosts = {
        ${dusk.domain} = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/static" = {
              root = ../static;
              tryFiles = "$uri =404";
            };
          };
        };

        ${dusk.tor.domain} = lib.mkIf config.dusk.tor.enable {
          enableACME = false;
          forceSSL = false;

          locations."/static" = {
            root = ../static;
            tryFiles = "$uri =404";
          };
        };
      };
    };
  };
}
