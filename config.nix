{
  username = "dusk";
  target = "vultr";
  domain = "disconnect.capital";
  tor.domain = "2lpubahflv3rvtronjxw3lmtwpn5jyidt6rxc7rbrqbce4rbe3yiwuqd.onion";
  email = "_@disconnect.capital";
  nostr.hex = "3238a74a7229b09415baf5850ff875780838f82831269a06ef8592f42bae1ac8";

  keys = {
    nodes.matrix-servers = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLVLXeD2c9/Q7HoWlccn3U95eb1hCwo+sQGpeaqlDYi root@ghost"
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
      generate = pkgs: ''${pkgs.openssl}/bin/openssl rand -hex 32 | tr -d '\n' > "$out"'';
    };

    tor-ed25519 = {
      path = ./secrets/dendrite.pem.age;
      generate = pkgs: ''${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$out" -N ""'';
    };
  };
}
