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

  keys.users.cfcosta = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7NVKxM60JPOU8GydRSNuUXDLiQdxA4C1I2VL8B8Iqr cfcosta@battlecruiser"
  ];

  secrets = {
    tor-ed25519 = {
      path = ./secrets/tor-ed25519.age;
      generate = pkgs: ''
        ${pkgs.tor}/bin/tor --keygen && cp ~/.tor/keys/ed25519_master_id_secret_key "$out"
      '';
    };

    "satellite-cdn-r2-access-key" = {
      path = ./secrets/satellite-cdn-r2-access-key.age;
      generate = pkgs: ''
        ${pkgs.cloudflared}/bin/cloudflared tunnel token list-r2-tokens --json | \
          ${pkgs.jq}/bin/jq -r '.[] | select(.name=="satellite-cdn") | .accessKeyId // empty' || \
        ${pkgs.cloudflared}/bin/cloudflared tunnel token generate-r2-token satellite-cdn --json | \
          ${pkgs.jq}/bin/jq -r '.accessKeyId'
      '';
    };

    "satellite-cdn-r2-secret-key" = {
      path = ./secrets/satellite-cdn-r2-secret-key.age;
      generate = pkgs: ''
        ${pkgs.cloudflared}/bin/cloudflared tunnel token list-r2-tokens --json | \
          ${pkgs.jq}/bin/jq -r '.[] | select(.name=="satellite-cdn") | .secretAccessKey // empty' || \
        ${pkgs.cloudflared}/bin/cloudflared tunnel token generate-r2-token satellite-cdn --json | \
          ${pkgs.jq}/bin/jq -r '.secretAccessKey'
      '';
    };

    "satellite-cdn-app-secret" = {
      path = ./secrets/satellite-cdn-app-secret.age;
      generate = pkgs: ''
        ${pkgs.openssl}/bin/openssl rand -hex 32 >"$out"
      '';
    };
  };
}
