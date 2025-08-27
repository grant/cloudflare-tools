#!/usr/bin/env bash

# Get token from https://dash.cloudflare.com/profile/api-tokens
CF_TOKEN="${CF_TOKEN:-}"

set -euo pipefail

if [[ -z "${CF_TOKEN:-}" ]]; then
  echo "Error: CF_TOKEN environment variable not set."
  echo "Export your Cloudflare API token first: export CF_TOKEN=your_token_here"
  exit 1
fi

echo "Fetching zones..."
# Get all zones with their IDs and names
zones=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  | jq -r '.result[] | "\(.id) \(.name)"')

if [[ -z "$zones" ]]; then
  echo "No zones found or invalid token."
  exit 1
fi

echo "Found zones:"
echo "$zones" | awk '{print "- "$2 " (" $1 ")"}'
echo

# Iterate through each zone and fetch DNS records
echo "Fetching DNS records for each zone..."
echo

while read -r zid zname; do
  echo "=== Zone: $zname (ID: $zid) ==="
  curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zid/dns_records?per_page=500" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
  | jq -r '.result[] | "\(.type)\t\(.name)\t\(.content)\tproxied=\(.proxied)"'
  echo
done <<< "$zones"
