{
  target = "vultr";
  domain = "disconnect.capital";

  keys.cfcosta = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7NVKxM60JPOU8GydRSNuUXDLiQdxA4C1I2VL8B8Iqr cfcosta@battlecruiser"
  ];

  secrets = {
    "dendrite.pem" = ./secrets/dendrite.pem.age;
    "dendrite.secret" = ./secrets/dendrite.secret.age;
  };
}
