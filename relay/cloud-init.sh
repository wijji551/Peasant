#!/bin/bash
# For Oracle Cloud's "Create instance" page: Show advanced options, Management, "Paste cloud-init script".
# The new machine runs this once, on its first start, and sets up the village server by itself (no SSH needed).
# It writes how it went to /var/log/village-setup.log.
exec > /var/log/village-setup.log 2>&1
sleep 20                                   # let the network settle on the first start
for i in $(seq 1 60); do      # for half an hour, in case the address comes late
  if sudo -u ubuntu -H bash -c 'curl -fsSL https://raw.githubusercontent.com/wijji551/Peasant/main/relay/setup.sh | bash'; then
    exit 0
  fi
  sleep 30
done
