# Cloudflare DNS Update Script

This script automates the process of updating DNS records in Cloudflare when moving a domain to a new host. It fetches all domains (zones) in your Cloudflare account, identifies DNS records pointing to an old server IP, and updates them to a new server IP.

## Author
**Shobhit Kumar Prabhakar**

---

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [How to Get Required Variables](#how-to-get-required-variables)
   - [Cloudflare Account Email (`auth_email`)](#cloudflare-account-email-auth_email)
   - [Cloudflare API Key (`auth_key`)](#cloudflare-api-key-auth_key)
   - [Old Server IP (`old_ip`)](#old-server-ip-old_ip)
   - [New Server IP (`new_ip`)](#new-server-ip-new_ip)
4. [How to Use the Script](#how-to-use-the-script)
5. [Script Workflow](#script-workflow)
6. [Example Output](#example-output)
7. [Notes](#notes)

---

## Features

- **Fetch All Domains**: Retrieves all domains (zones) in your Cloudflare account in a single request.
- **Update DNS Records**: Updates all DNS records pointing to the old server IP to the new server IP.
- **Error Handling**: Handles errors gracefully, such as invalid credentials, API rate limits, or missing DNS records.
- **Logging**: Provides detailed logs for each step, making it easier to debug and track progress.
- **Rate Limiting**: Adds a 1-second delay between API requests to avoid hitting Cloudflare's rate limits.

---

## Prerequisites

- **Bash Shell**: Ensure you have a Bash shell environment to run the script.
- **cURL**: The script uses `curl` to interact with the Cloudflare API.
- **jq**: The script uses `jq` to parse JSON responses from the Cloudflare API. Install it using your package manager:
  - On Ubuntu/Debian: `sudo apt-get install jq`
  - On macOS: `brew install jq`

---

## How to Get Required Variables

### Cloudflare Account Email (`auth_email`)
This is the email address you use to log in to your Cloudflare account.

### Cloudflare API Key (`auth_key`)
1. Log in to your Cloudflare account.
2. Navigate to the **My Profile** section.
3. Click on the **API Tokens** tab.
4. Under the **API Keys** section, find the **Global API Key** and click **View**.
5. Enter your Cloudflare account password to reveal the API key.
6. Copy the API key and use it as the `auth_key` in the script.

### Old Server IP (`old_ip`)
This is the current IP address that your DNS records are pointing to. You can find this by:
- Checking the DNS records for your domain in the Cloudflare dashboard.
- Using a tool like `dig` or `nslookup`:
  ```bash
  dig +short example.com
  ```

### New Server IP (`new_ip`)
This is the new IP address that you want your DNS records to point to. This is typically provided by your new hosting provider.

---

## How to Use the Script

1. **Save the Script**:
   - Save the script to a file, e.g., `update_dns_all_domains.sh`.

2. **Make the Script Executable**:
   - Run the following command to make the script executable:
     ```bash
     chmod +x update_dns_all_domains.sh
     ```

3. **Set the Variables**:
   - Open the script in a text editor and replace the placeholders with the appropriate values:
     ```bash
     auth_email="user@example.com"
     auth_key="1234567890abcdef1234567890abcdef"
     old_ip="192.0.2.1"
     new_ip="203.0.113.1"
     ```

4. **Run the Script**:
   - Execute the script by running:
     ```bash
     ./update_dns_all_domains.sh
     ```

---

## Script Workflow

1. **Fetch All Domains**:
   - The script fetches all domains (zones) in your Cloudflare account using a single API request with `per_page=500`.

2. **Fetch DNS Records**:
   - For each domain, it fetches DNS records of type `A` that point to the `old_ip`.

3. **Update DNS Records**:
   - The script updates each DNS record to point to the `new_ip`.

4. **Logging**:
   - The script logs each step to the console, making it easy to track progress and debug issues.

---

## Example Output

```
[2023-10-15 12:34:56] Fetching all zones (domains) in the Cloudflare account...
[2023-10-15 12:34:57] Found 45 domains in the Cloudflare account.
[2023-10-15 12:34:57] Processing domain: example.com (Zone ID: abcd1234abcd1234abcd1234abcd1234)...
[2023-10-15 12:34:58] Fetching DNS records for domain example.com pointing to 192.0.2.1...
[2023-10-15 12:34:59] Found 2 DNS records to update for domain example.com.
[2023-10-15 12:34:59] Updating DNS record xyz123xyz123xyz123xyz123 to point to 203.0.113.1...
[2023-10-15 12:35:00] Successfully updated DNS record xyz123xyz123xyz123xyz123 for domain example.com.
[2023-10-15 12:35:01] DNS update process completed for all domains.
```

---

## Notes

- **Assumption**: This script assumes your Cloudflare account has fewer than 500 domains. If your account has more than 500 domains, you will need to implement pagination.
- **Rate Limits**: Cloudflare's API has rate limits. If you have many domains or DNS records, consider increasing the delay between updates or contacting Cloudflare support for a higher rate limit.
- **Testing**: Always test the script on a non-production domain or with a small set of DNS records before running it on critical domains.

---

This script simplifies the process of updating DNS records in Cloudflare when moving to a new host. By automating the task, it reduces the risk of human error and saves time. Ensure you have the correct values for the required variables and test the script before using it in a production environment.

Let me know if you need further assistance!
