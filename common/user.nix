{ dusk, lib, ... }:
let
  inherit (builtins) attrValues;
  inherit (lib) flatten;
in
{
  config = {
    nix.settings.trusted-users = [ dusk.username ];

    security.sudo.extraRules = [
      {
        users = [ dusk.username ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    users.users.${dusk.username} = {
      extraGroups = [ "wheel" ];
      isNormalUser = true;
      openssh.authorizedKeys.keys = flatten (attrValues dusk.keys.users);
    };
  };
}
