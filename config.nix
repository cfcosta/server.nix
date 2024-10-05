{
  target = "vultr";
  domain = "disconnect.capital";
  tor.domain = "2lpubahflv3rvtronjxw3lmtwpn5jyidt6rxc7rbrqbce4rbe3yiwuqd.onion";
  email = "_@disconnect.capital";
  nostr.hex = "8a64d83fd8d8a8c5ae622417e733238a348c20dd823f3f49b7db0b3c51f87761";

  keys = {
    nodes.matrix-servers = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC53rEpNA+0GQtsbkEyRfUeaFo2k9+U2w6oeEYqljz7S root@ghost"
    ];

    users.cfcosta = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7NVKxM60JPOU8GydRSNuUXDLiQdxA4C1I2VL8B8Iqr cfcosta@battlecruiser"
    ];
  };

  secrets = {
    "dendrite.pem" = {
      path = ./secrets/dendrite.pem.age;
      generate = pkgs: ''${pkgs.dendrite}/bin/generate-keys --private-key "$out"'';
    };

    "dendrite.secret" = {
      path = ./secrets/dendrite.secret.age;
      generate = pkgs: ''${pkgs.openssl}/bin/openssl rand -hex 32 | tr -d '\n' > "$out"'';
    };

    "dendrite-sliding-sync.secret" = {
      path = ./secrets/dendrite-sliding-sync.secret.age;
      generate = pkgs: ''
        echo "SYNCV3_SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 32)" > "$out"
      '';
    };

    tor-ed25519 = {
      path = ./secrets/dendrite.pem.age;
      generate = pkgs: ''${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$out" -N ""'';
    };
  };
}
