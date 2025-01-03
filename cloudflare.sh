#!/bin/bash
auth_email="YOUR_LOGIN_ID"
auth_key="YOUR_CLOUDFLARE_AUTH_KEY"
zone_id="ZONE_ID_OF_THE_DOMAIN"
old_ip="OLD_SERVER_IP"
new_ip="NEW_SERVER_IP"

record_list=( $(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?per_page=500&type=A&content=${old_ip}" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | jq -r '.result[].id') )

for id in "${record_list[@]}"
do
	curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${id}" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data '{"content":$new_ip}'
done