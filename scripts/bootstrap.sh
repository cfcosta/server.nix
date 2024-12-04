#!/usr/bin/env bash

HOST="${1}"
FLAKE_TARGET="${2:-.#bootstrap}"

[ -z "${HOST}" ] && _fatal "Usage: ${0} <user@hostname>"

setup_host

_info "Provisioning a new machine..."
_info "Target address: $(_blue "${HOST}")"
_info "Installing profile: $(_blue "${FLAKE_TARGET}")"

CMD="nixos-anywhere --flake ${FLAKE_TARGET} ${HOST}"
_info "Running command: $(_blue "${CMD}")"
${CMD}

_info "Waiting a little bit for the new host to boot"
sleep 10

_info "Requesting the new host key."
HOST_KEY=$(ssh-keyscan -t ed25519 "${HOST%%@*}" 2>/dev/null)

[ -z "${HOST_KEY}" ] && _fatal "Could not retrieve host key"
[ -f secrets/keys ] || _fatal "Could not find host keys file"

_info "Adding host key $(_red "${HOST_KEY}") to secrets/keys"
tee -a "${HOST_KEY}" secrets/keys

_info "Done, updating secrets to account for new host..."

pushd secrets || _fatal "Could not find secrets directory."
agenix -r
popd || _fatal "Could not find root directory."

_info "Done!"
