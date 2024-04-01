#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

FMTCURID=$(id -u)
FMTDIR=$(dirname "$(readlink -f "$0")")

if [[ "$FMTCURID" != "0" ]]; then
	echo "The script is intended to run under root"
	exit 1
fi


if [[ ! -f "/etc/rsyslog.d/50-default.conf" ]]; then
	echo "rsyslog.d/50-default.conf not found, there is no place to put the new config file"
	exit 1
fi


mkdir -p /var/log/rugov_blacklist
chown syslog:adm /var/log/rugov_blacklist
chmod 0755 /var/log/rugov_blacklist

cat "$FMTDIR/51-iptables-rugov.conf" > /etc/rsyslog.d/51-iptables-rugov.conf

service rsyslog restart

cat "$FMTDIR/updater.sh" > /var/log/rugov_blacklist/updater.sh
chmod +x /var/log/rugov_blacklist/updater.sh
touch /var/log/rugov_blacklist/blacklist.txt

/var/log/rugov_blacklist/updater.sh

ln -s /var/log/rugov_blacklist/updater.sh /etc/cron.daily/rugov_updater.sh

echo "Installation finished successfully!"
