#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

FMTCURID=$(id -u)
FMTDIR=$(dirname "$(readlink -f "$0")")
FMTDOLOGS=""

if [[ -n ${1+x} && "$1" == "--log" ]];then
	FMTDOLOGS="do"
fi

if [[ "$FMTCURID" != "0" ]]; then
	echo "The script is intended to run under root"
	exit 1
fi

if [[ ! -d "/etc/iptables/" ]]; then
	echo "The script is intended to be used with iptables. Are you sure all the necessary packages are installed? Run: 'sudo apt-get install iptables-persistent'"
	exit 2
fi

if [[ "$FMTDOLOGS" ]]; then
	echo "Installing rsyslogd config..."
	if [[ ! -d "/etc/rsyslog.d/" ]]; then
		echo "/etc/rsyslog.d/ not found, are you sure rsyslogd is installed? Run: 'sudo apt-get install rsyslog'"
		exit 1
	fi

	cat "$FMTDIR/51-iptables-rugov.conf" > /etc/rsyslog.d/51-iptables-rugov.conf

	service rsyslog restart
fi

echo "Installing common files..."
mkdir -p /var/log/rugov_blacklist
chown nobody:adm /var/log/rugov_blacklist
chmod 0755 /var/log/rugov_blacklist


cat "$FMTDIR/updater.sh" > /var/log/rugov_blacklist/updater.sh
chmod +x /var/log/rugov_blacklist/updater.sh
touch /var/log/rugov_blacklist/blacklist.txt

echo "Running initial setup process..."
/var/log/rugov_blacklist/updater.sh

ln -sf /var/log/rugov_blacklist/updater.sh /etc/cron.daily/rugov_updater

echo "Installation finished successfully!"
