{
  username = "dusk";
  target = "vultr";
  domain = "disconnect.capital";
  tor.domain = "2lpubahflv3rvtronjxw3lmtwpn5jyidt6rxc7rbrqbce4rbe3yiwuqd.onion";
  email = "_@disconnect.capital";

  keys = {
    nodes.matrix-servers = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhoa8rEi6Md2kHC6+9hlLK/zS6PmDYfiV0WkI4Y9f2t root@ghost"
    ];

    users.cfcosta = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7NVKxM60JPOU8GydRSNuUXDLiQdxA4C1I2VL8B8Iqr cfcosta@battlecruiser"
    ];
  };

  secrets = {
    "dendrite.pem" = ./secrets/dendrite.pem.age;
    "dendrite.secret" = ./secrets/dendrite.secret.age;
    "dendrite-sliding-sync.secret" = ./secrets/dendrite-sliding-sync.secret.age;
  };
}
