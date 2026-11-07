# edges

What runs on the edge machines (the Raspberry Pi controllers at each home). For now, that's WireGuard.
The design and the network topology live in mono, under `systems/wireguard/edges.md`. Agents: read [AGENTS.md](AGENTS.md).

## Bootstrap a controller (once)

From the workstation:

```sh
scp ~/.ssh/crypt.key.controller.f        bemo@<controller>:.ssh/   # its own key only
scp ~/.ssh/edges-deploy ~/.ssh/edges-deploy.pub bemo@<controller>:.ssh/
```

On the controller, as bemo:

```sh
cat >> ~/.ssh/config <<'EOF'
Host github-edges
    HostName github.com
    User git
    IdentityFile ~/.ssh/edges-deploy
    IdentitiesOnly yes
EOF
mkdir -p ~/gitroot && git clone github-edges:bemowski/edges.git ~/gitroot/edges
~/gitroot/edges/wireguard/install.sh controller.f
```

`install.sh` stops the old WireGuard setup (moving it to `/root/wireguard.pre-edges-*/`), applies
this host's generated config, and enables the timers.

## Day to day

| | |
|---|---|
| change the network | edit mono `systems/wireguard/topology.yaml`, then `wggen check` and `wggen push` there |
| controllers pick it up | within 5 minutes (`edges-sync.timer`); `journalctl -u edges-sync` |
| apply now | `sudo systemctl start edges-sync` |
| health | `sudo bin/wg-check` |
| remove | `wireguard/uninstall.sh` |
