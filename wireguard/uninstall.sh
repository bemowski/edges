#!/bin/sh
# Undo install.sh: stop the timers and the edges interfaces, remove what was installed.
# The pre-edges setup is not restored; its files are in /root/wireguard.pre-edges-*/.
# /etc/edges/wg.key (this node's identity, enrolled in mono keys/) is kept, so a reinstall reuses it;
# remove it by hand to retire the node. Run as bemo (uses sudo).
set -e
sudo systemctl disable --now edges-sync.timer edges-wg-reresolve.timer 2>/dev/null || true
for iface in $(sudo cat /etc/edges/managed 2>/dev/null); do
    sudo systemctl disable --now "wg-quick@$iface" || true
    sudo rm -f "/etc/wireguard/$iface.conf"
done
sudo rm -rf /etc/wireguard/.edges-prev /etc/wireguard/.edges-staging
sudo nft delete table inet edges_wg 2>/dev/null || true
for unit in edges-sync.service edges-sync.timer edges-wg-reresolve.service edges-wg-reresolve.timer; do
    sudo rm -f "/etc/systemd/system/$unit"
done
sudo systemctl daemon-reload
sudo rm -f /etc/sysctl.d/99-edges-wg.conf
sudo find /etc/edges -mindepth 1 -maxdepth 1 ! -name wg.key -exec rm -rf {} + 2>/dev/null || true
