{
  target = "vultr";
  domain = "disconnect.capital";
  tor.domain = "2lpubahflv3rvtronjxw3lmtwpn5jyidt6rxc7rbrqbce4rbe3yiwuqd.onion";
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
      generate = pkgs: ''${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$out" -N ""'';
    };
  };
}
