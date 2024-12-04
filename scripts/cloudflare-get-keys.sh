#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BUCKET_NAME="${1:-}"
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-}"

[ -z "$BUCKET_NAME" ] && _fatal "Usage: $0 <bucket-name>"
[ -z "$ACCOUNT_ID" ] && _fatal "CLOUDFLARE_ACCOUNT_ID environment variable must be set"

# Use existing AWS CLI config but override endpoint for R2
ENDPOINT="https://${ACCOUNT_ID}.r2.cloudflarestorage.com"

# Check if bucket exists
_info "Checking if bucket exists: $(_blue "$BUCKET_NAME")"
if ! aws s3api head-bucket --endpoint-url "$ENDPOINT" --bucket "$BUCKET_NAME" 2>/dev/null; then
	_info "Bucket does not exist, creating: $(_blue "$BUCKET_NAME")"
	aws s3api create-bucket --endpoint-url "$ENDPOINT" --bucket "$BUCKET_NAME"
fi

# Get credentials from AWS CLI config
AWS_CREDS_FILE="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
AWS_PROFILE="${AWS_PROFILE:-default}"

[ ! -f "$AWS_CREDS_FILE" ] && _fatal "AWS credentials file not found at: $AWS_CREDS_FILE"

# Extract credentials from the AWS credentials file
_info "Reading credentials from profile: $(_blue "$AWS_PROFILE")"
ACCESS_KEY=$(aws configure get aws_access_key_id --profile "$AWS_PROFILE")
SECRET_KEY=$(aws configure get aws_secret_access_key --profile "$AWS_PROFILE")

[ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ] && _fatal "Failed to read credentials from AWS profile: $AWS_PROFILE"

_info "Successfully retrieved credentials from AWS CLI config"

# Output the keys to files
echo "$ACCESS_KEY" >"access-key"
echo "$SECRET_KEY" >"secret-access-key"

_info "Credentials saved to access-key and secret-access-key files"
