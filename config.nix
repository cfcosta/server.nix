{
  target = "vultr";
  domain = "disconnect.capital";

  keys = {
    nodes.matrix-servers = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFyMGkYxHwDlumYVAfapFzPfcctnd01O7pbQ36xqTVyg root@ghost"
    ];

    users.cfcosta = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7NVKxM60JPOU8GydRSNuUXDLiQdxA4C1I2VL8B8Iqr cfcosta@battlecruiser"
    ];
  };

  secrets = {
    "dendrite.pem" = ./secrets/dendrite.pem.age;
    "dendrite.secret" = ./secrets/dendrite.secret.age;
  };
}
