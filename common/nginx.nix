{ dusk, ... }:
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
        };

        ${dusk.tor.domain} = {
          enableACME = false;
          forceSSL = false;
        };
      };
    };
  };
}
