# Server Infrastructure

## How-Tos

### Provisioning a New Server

Inside a `nix-shell`, run the following command:

```sh
bootstrap <user>@<ip>
```

### Deploying

Inside a `nix-shell`, run the following command:

```sh
deploy .#<profile> <user>@<ip>
```

Where `<profile>` can be found either on the `deploy.nodes` key on `flake.nix`, or on the `profiles/` folder.

