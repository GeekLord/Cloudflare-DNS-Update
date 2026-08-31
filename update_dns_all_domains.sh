#!/bin/bash

# Author: Shobhit Kumar Pravhakar

# Description: Script to update DNS records in Cloudflare for all domains when moving to a new host.

# Variables
api_token="your_api_token_here"  # Your Cloudflare API token (replace with actual token)
old_ip="1.1.1.1"          # Old server IP address
new_ip="2.2.2.2"          # New server IP address
dry_run="false"           # Set to "true" to simulate updates without modifying Cloudflare

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
if [[ -z "$api_token" || -z "$old_ip" || -z "$new_ip" ]]; then
    log "Error: One or more required variables are not set."
    exit 1
fi

# Validate old and new IP addresses
validate_ip "$old_ip"
validate_ip "$new_ip"

# Fetch all zones (domains) in a single request
# The parameter per_page=500 fetches up to 500 zones at once to bypass the need for immediate pagination logic.
log "Fetching all zones (domains) in the Cloudflare account..."
response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?per_page=500" \
    -H "Authorization: Bearer $api_token")

# Check if the API request was successful
if [[ $(echo "$response" | jq -r '.success') != "true" ]]; then
    log "Error: Failed to fetch zones. Response: $(echo "$response" | jq -r '.errors[].message')"
    exit 1
fi

# Extract zone IDs and domain names
# Extracts an array of zone IDs using jq by parsing the 'result' list inside the API response.
zone_ids=$(echo "$response" | jq -r '.result[].id')

if [[ -z "$zone_ids" ]]; then
    log "No domains found in the Cloudflare account."
    exit 0
fi

log "Found $(echo "$zone_ids" | wc -l) domains in the Cloudflare account."

# Iterate over each zone and update DNS records
for zone_id in $zone_ids; do
    # Uses jq to filter and match the current zone ID against the fetched results, extracting its corresponding domain name.
    domain_name=$(echo "$response" | jq -r --arg zone_id "$zone_id" '.result[] | select(.id == $zone_id) | .name')
    log "Processing domain: $domain_name (Zone ID: $zone_id)..."

    # Fetch DNS records pointing to the old IP
    # Includes type=A and content=$old_ip to retrieve only the A records that are currently pointing to the old server IP.
    log "Fetching DNS records for domain $domain_name pointing to $old_ip..."
    record_list=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?per_page=500&type=A&content=${old_ip}" \
        -H "Authorization: Bearer $api_token")

    # Check if the API request was successful
    if [[ $(echo "$record_list" | jq -r '.success') != "true" ]]; then
        log "Error: Failed to fetch DNS records for domain $domain_name. Response: $(echo "$record_list" | jq -r '.errors[].message')"
        continue
    fi

    # Extract record IDs
    # Uses jq to retrieve a list of record IDs that specifically match the old IP and are identified for an update.
    record_ids=$(echo "$record_list" | jq -r '.result[].id')

    if [[ -z "$record_ids" ]]; then
        log "No DNS records found for domain $domain_name pointing to $old_ip."
        continue
    fi

    log "Found $(echo "$record_ids" | wc -l) DNS records to update for domain $domain_name."

    # Update each DNS record
    for id in $record_ids; do
        if [[ "$dry_run" == "false" ]]; then
            log "Updating DNS record $id to point to $new_ip..."
            response=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${id}" \
                -H "Authorization: Bearer $api_token" \
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

        else
            log "[DRY RUN] Would update DNS record $id to point to $new_ip..."
        fi

    done
done

if [[ "$dry_run" == "false" ]]; then
    log "DNS update process completed for all domains."
else
    log "[DRY RUN] DNS update process completed for all domains. No changes were made."
fi
