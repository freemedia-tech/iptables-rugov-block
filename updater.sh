#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Paths to files with IP addresses
OLD_IP_FILE="/var/log/rugov_blacklist/old_blacklist.txt"
NEW_IP_FILE="/var/log/rugov_blacklist/blacklist.txt"
FMT_LOGS=""
if [[ -f "/etc/rsyslog.d/51-iptables-rugov.conf" ]]; then
	FMT_LOGS="do"
fi

# Rename the existing blacklist.txt file to old_blacklist.txt
mv "$NEW_IP_FILE" "$OLD_IP_FILE"

# Copy the blacklist.txt file from the source via the link
if ! sudo wget -O "$NEW_IP_FILE" https://github.com/C24Be/AS_Network_List/raw/main/blacklists/blacklist.txt; then
	echo "Failed to load new blacklist. Lets leave the old list unchanged."
	echo "$(date +"%Y-%m-%d %H:%M:%S") - Failed to load new blacklist. Lets leave the old list unchanged." >> /var/log/rugov_blacklist/blacklist_updater.log
	exit 1
fi

# Read IP addresses from old file
old_addresses=()
while IFS= read -r ip || [[ -n "$ip" ]]; do
old_addresses+=("$ip")
done < "$OLD_IP_FILE"

# Read IP addresses from a new file
new_addresses=()
while IFS= read -r ip || [[ -n "$ip" ]]; do
new_addresses+=("$ip")
done < "$NEW_IP_FILE"

# Add new addresses and remove old ones from the rules
added=0
removed=0
for addr in "${new_addresses[@]}"; do
	if ! sudo iptables -t raw -C PREROUTING -s "$addr" -j DROP &>/dev/null; then
		if [[ "$FMT_LOGS" ]]; then
			iptables -t raw -A PREROUTING -s "$addr" -j LOG --log-prefix "Blocked RUGOV IP attempt: "
		fi
		iptables -t raw -A PREROUTING -s "$addr" -j DROP
		((added++)) || true
	fi
done

for addr in "${old_addresses[@]}"; do
	if ! grep -q "$addr" "$NEW_IP_FILE"; then
		iptables -t raw -D PREROUTING -s "$addr" -j LOG --log-prefix "Blocked RUGOV IP attempt: " || true
		iptables -t raw -D PREROUTING -s "$addr" -j DROP
		((removed++)) || true
	fi
done

# Save firewall rules to a file
iptables-save > /etc/iptables/rules.v4

# Display information about added and deleted addresses
echo "Added addresses to the blacklist: $added"
echo "Addresses removed from the blacklist: $removed"

# Add an entry to the log file
echo "$(date +"%Y-%m-%d %H:%M:%S") - Added addresses to the blacklist: $added, addresses removed from the blacklist: $removed" >> /var/log/rugov_blacklist/blacklist_updater.log
