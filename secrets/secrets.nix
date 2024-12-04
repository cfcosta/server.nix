with builtins;
let
  config = import ../config.nix;

  hosts = filter (k: k != "" && k != [ ]) (split "\n" (readFile ./keys));
  users = concatLists (attrValues config.keys.users);
in
listToAttrs (
  map (name: {
    inherit name;
    value = {
      publicKeys = hosts ++ users;
    };
  }) (filter (name: match ".*\\.age$" name != null) (attrNames (readDir ./.)))
)
