rec {
  target = "vultr";
  domain = "disconnect.capital";
  tor.domain = "4gezqic2tc2lz6vmpnjavwnemu6m2k27nlrpvyyqy6j7yufe7bsuehad.onion";
  email = "_@disconnect.capital";

  profiles.nostr-relay = rec {
    ownerPubkey = "8a64d83fd8d8a8c5ae622417e733238a348c20dd823f3f49b7db0b3c51f87761";

    name = domain;
    description = "The Nostr relay for the disconnect.capital peeps.";
    url = "nostr.${domain}";
    icon = "https://${domain}/static/icon.png";
    contact = "_@disconnect.capital";

    users = {
      _.pubkey = ownerPubkey;
      cfcosta.pubkey = "cfa3df9203c440a5b94b1f863094e683412ce9d422a7f99c5346e43fe2001d92";
    };
  };

  accounts.cloudflare.account_id = "18b5845d91b38a67938367ff0bd9f8c3";

  keys.users.cfcosta = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7NVKxM60JPOU8GydRSNuUXDLiQdxA4C1I2VL8B8Iqr cfcosta@battlecruiser"
  ];

  secrets = {
    tor-ed25519 = {
      path = ./secrets/tor-ed25519.age;
      generate =
        pkgs: "${pkgs.tor}/bin/tor --keygen && cp ~/.tor/keys/ed25519_master_id_secret_key \"$out\"";
    };

    "satellite-cdn-r2-access-key" = {
      path = ./secrets/satellite-cdn-r2-access-key.age;
      generate =
        _:
        "CLOUDFLARE_ACCOUNT_ID=\"${accounts.cloudflare.account_id}\" bash scripts/cloudflare-get-keys.sh satellite-cdn && cat access-key > \"$out\" && rm access-key secret-access-key";
    };

    "satellite-cdn-r2-secret-key" = {
      path = ./secrets/satellite-cdn-r2-secret-key.age;
      generate =
        _:
        "CLOUDFLARE_ACCOUNT_ID=\"${accounts.cloudflare.account_id}\" bash scripts/cloudflare-get-keys.sh satellite-cdn && cat secret-access-key > \"$out\" && rm access-key secret-access-key";
    };

    "satellite-cdn-app-secret" = {
      path = ./secrets/satellite-cdn-app-secret.age;
      generate = pkgs: "${pkgs.openssl}/bin/openssl rand -hex 32 >\"$out\"";
    };
  };
}
