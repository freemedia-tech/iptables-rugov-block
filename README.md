# Keep your webserver clean from RKN bots using iptables.

This project uses blacklists from https://github.com/C24Be/AS_Network_List/blob/main/blacklists/blacklist.txt

Pay attention! This script was tested on Ubuntu 22.04, there could be any issues on other versions or Linuxes!

You can find all the original instructions from the author of this solution here: [original_instruction.pdf](original_instruction.pdf)

## How to use

Clone this repo to your server and run `sudo ./install.sh`
To enable logging of all requests from forbidden ips run `sudo ./install.sh --log` instead. This requires rsyslogd to be up and running. If you are unsure - install it without logs.
All the logs are in the file /var/log/rugov_blacklist/blacklist.log . Keep in mind - if your target could be interesting, you can get a lot of disk space used by this log!

## What it does

- adds rsyslogd rules in /etc/rsyslog.d/51-iptables-rugov.conf (only with --log)
- makes directory /var/log/rugov_blacklist/
- puts there all necessary files
- runs the update process 
- installs cron script to /etc/cron.daily/rugov_updater.sh

