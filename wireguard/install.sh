#!/bin/sh
# Install edges WireGuard on a controller. Run as bemo (uses sudo); idempotent.
#   wireguard/install.sh <controller>      e.g. controller.f
# Needs /etc/edges/wg.key, this box's own WireGuard key: run `wggen enroll <controller> <ssh-host>` in mono first.
# The old (pre-edges) WireGuard setup is stopped and moved aside first: see teardown-legacy.sh.
set -e
HOST=${1:?usage: $0 <controller>}
REPO=$(cd "$(dirname "$0")/.." && pwd)
COMMON=$REPO/wireguard/common

[ -d "$REPO/wireguard/hosts/$HOST" ] || { echo "no generated config for $HOST" >&2; exit 1; }
sudo test -s /etc/edges/wg.key || {
    echo "/etc/edges/wg.key is missing: run \`wggen enroll $HOST <ssh-host>\` from the workstation" >&2; exit 1; }

sudo apt-get install -y wireguard-tools nftables git python3 iputils-ping

sudo install -d -m 755 /etc/edges
echo "$HOST" | sudo tee /etc/edges/host >/dev/null
for unit in edges-sync.service edges-sync.timer edges-wg-reresolve.service edges-wg-reresolve.timer; do
    sed "s#@REPO@#$REPO#g" "$COMMON/$unit" | sudo tee "/etc/systemd/system/$unit" >/dev/null
done
sudo systemctl daemon-reload

sudo "$REPO/wireguard/teardown-legacy.sh"
sudo install -m 644 "$COMMON/99-edges-wg.conf" /etc/sysctl.d/99-edges-wg.conf
sudo sysctl -q -p /etc/sysctl.d/99-edges-wg.conf
sudo "$REPO/bin/wg-apply"
sudo systemctl enable --now edges-sync.timer edges-wg-reresolve.timer
sudo wg show
