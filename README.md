# Disconnect Server Provisioning Tool

## How-Tos

### Re-provisioning Secrets

Once you clone the repository, you might need to re-generate all the server secrets (as you will not have access to them, which you can do by adding your key on `config.nix`), then running:

```sh
server-re-generate-secrets
```

Then, once you have access to the secrets, you can re-encrypt them with newer keys by running:

```sh
server-reencrypt-secrets
```

### Provisioning a New Server

Inside a `nix-shell`, run the following command:

```sh
server-bootstrap <user>@<ip>
```

After bootstrapping the server, there is currently some manual book-keeping you need to do:

1. The SSH host keys are changed after bootstrap, so you need to remove the key on your `~/.ssh/known_hosts`.
2. You need to add the new server host key to `config.nix`.
2. You need to re-encrypt the secrets with the new keys, by running the following command:

```sh
server-reencrypt-secrets
```

### Deploying

Inside a `nix-shell`, run the following command:

```sh
server-deploy .#<profile> <ip>
```

Where `<profile>` can be found either on the `deploy.nodes` key on `flake.nix`, or on the `profiles/` folder.

