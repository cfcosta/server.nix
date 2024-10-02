{ dusk, ... }:
{
  config = {
    security.acme = {
      acceptTerms = true;

      certs.${dusk.domain}.email = dusk.domainOwner;
    };

    services.nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

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
