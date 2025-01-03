#!/bin/bash

# Author: Shobhit Kumar Pravhakar
# Description: Script to update DNS records in Cloudflare for all domains when moving to a new host.

# Variables
auth_email="YOUR_LOGIN_ID"               # Your Cloudflare account email
auth_key="YOUR_CLOUDFLARE_AUTH_KEY"      # Your Cloudflare API key
old_ip="OLD_SERVER_IP"                   # Old server IP address
new_ip="NEW_SERVER_IP"                   # New server IP address

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Validate IP address format
validate_ip() {
    if [[ ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "Error: Invalid IP address format: $1"
        exit 1
    fi
}

# Validate required variables
if [[ -z "$auth_email" || -z "$auth_key" || -z "$old_ip" || -z "$new_ip" ]]; then
    log "Error: One or more required variables are not set."
    exit 1
fi

# Validate old and new IP addresses
validate_ip "$old_ip"
validate_ip "$new_ip"

# Fetch all zones (domains) in a single request
log "Fetching all zones (domains) in the Cloudflare account..."
response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?per_page=500" \
    -H "X-Auth-Email: $auth_email" \
    -H "X-Auth-Key: $auth_key" \
    -H "Content-Type: application/json")

# Check if the API request was successful
if [[ $(echo "$response" | jq -r '.success') != "true" ]]; then
    log "Error: Failed to fetch zones. Response: $(echo "$response" | jq -r '.errors[].message')"
    exit 1
fi

# Extract zone IDs and domain names
zone_ids=$(echo "$response" | jq -r '.result[].id')
domain_names=$(echo "$response" | jq -r '.result[].name')

if [[ -z "$zone_ids" ]]; then
    log "No domains found in the Cloudflare account."
    exit 0
fi

log "Found $(echo "$zone_ids" | wc -l) domains in the Cloudflare account."

# Iterate over each zone and update DNS records
for zone_id in $zone_ids; do
    domain_name=$(echo "$response" | jq -r --arg zone_id "$zone_id" '.result[] | select(.id == $zone_id) | .name')
    log "Processing domain: $domain_name (Zone ID: $zone_id)..."

    # Fetch DNS records pointing to the old IP
    log "Fetching DNS records for domain $domain_name pointing to $old_ip..."
    record_list=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?per_page=500&type=A&content=${old_ip}" \
        -H "X-Auth-Email: $auth_email" \
        -H "X-Auth-Key: $auth_key" \
        -H "Content-Type: application/json")

    # Check if the API request was successful
    if [[ $(echo "$record_list" | jq -r '.success') != "true" ]]; then
        log "Error: Failed to fetch DNS records for domain $domain_name. Response: $(echo "$record_list" | jq -r '.errors[].message')"
        continue
    fi

    # Extract record IDs
    record_ids=$(echo "$record_list" | jq -r '.result[].id')

    if [[ -z "$record_ids" ]]; then
        log "No DNS records found for domain $domain_name pointing to $old_ip."
        continue
    fi

    log "Found $(echo "$record_ids" | wc -l) DNS records to update for domain $domain_name."

    # Update each DNS record
    for id in $record_ids; do
        log "Updating DNS record $id to point to $new_ip..."
        response=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${id}" \
            -H "X-Auth-Email: $auth_email" \
            -H "X-Auth-Key: $auth_key" \
            -H "Content-Type: application/json" \
            --data "{\"content\":\"$new_ip\"}")

        # Check if the update was successful
        if [[ $(echo "$response" | jq -r '.success') != "true" ]]; then
            log "Error: Failed to update DNS record $id for domain $domain_name. Response: $(echo "$response" | jq -r '.errors[].message')"
        else
            log "Successfully updated DNS record $id for domain $domain_name."
        fi

        # Add a delay to avoid hitting rate limits
        sleep 1
    done
done

log "DNS update process completed for all domains."