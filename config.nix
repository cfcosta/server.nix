{
  target = "vultr";
  domain = "disconnect.capital";
  tor.domain = "4gezqic2tc2lz6vmpnjavwnemu6m2k27nlrpvyyqy6j7yufe7bsuehad.onion";
  email = "_@disconnect.capital";
  nostr.hex = "8a64d83fd8d8a8c5ae622417e733238a348c20dd823f3f49b7db0b3c51f87761";

  keys = {
    nodes.server = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC53rEpNA+0GQtsbkEyRfUeaFo2k9+U2w6oeEYqljz7S root@ghost"
    ];

    users.cfcosta = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7NVKxM60JPOU8GydRSNuUXDLiQdxA4C1I2VL8B8Iqr cfcosta@battlecruiser"
    ];
  };

  secrets = {
    tor-ed25519 = {
      path = ./secrets/tor-ed25519.age;
      generate = pkgs: ''
        ${pkgs.tor}/bin/tor --keygen && cp ~/.tor/keys/ed25519_master_id_secret_key "$out"
      '';
    };
  };
}
