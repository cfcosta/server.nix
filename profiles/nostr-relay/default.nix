{ config, dusk, ... }:
{
  imports = [
    ../../common
    ./services/chronicle.nix
    ./services/nginx.nix
    ./services/satellite-cdn.nix
  ];

  config.age.secrets = {
    "satellite-cdn-r2-access-key" = {
      file = dusk.secrets."satellite-cdn-r2-access-key".path;
      mode = "0600";
      owner = "satellite-cdn";
    };

    "satellite-cdn-r2-secret-key" = {
      file = dusk.secrets."satellite-cdn-r2-secret-key".path;
      mode = "0600";
      owner = "satellite-cdn";
    };

    "satellite-cdn-app-secret" = {
      file = dusk.secrets."satellite-cdn-app-secret".path;
      mode = "0600";
      owner = "satellite-cdn";
    };
  };

  config.dusk = {
    chronicle = {
      inherit (dusk.profiles.nostr-relay)
        ownerPubkey
        name
        description
        url
        icon
        contact
        ;

      enable = true;
    };

    satellite-cdn = {
      enable = true;
      s3AccessKeyId = config.age.secrets."satellite-cdn-r2-access-key".path;
      s3SecretAccessKey = config.age.secrets."satellite-cdn-r2-secret-key".path;
      appSecretKey = config.age.secrets."satellite-cdn-app-secret".path;
      s3Bucket = "satellite-cdn";
      cfAccountId = dusk.accounts.cloudflare.account_id;
      lightningProviderPubkey = "your-lightning-provider-pubkey";
      lightningCallbackUrl = "your-lightning-callback-url";
      cdnEndpoint = "cdn.${dusk.domain}";
      blobEndpoint = "blob.${dusk.domain}";
    };

    tor.enable = true;
  };
}
