{ dusk, ... }:
{
  config = {
    security.acme = {
      acceptTerms = true;

      certs.${dusk.domain}.email = dusk.domainOwner;
    };

    services.nginx = {
      enable = true;

      virtualHosts.${dusk.domain} = {
        enableACME = true;
        forceSSL = true;
      };
    };
  };
}
