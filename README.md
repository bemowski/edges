# edges

What runs on the edge machines (the Raspberry Pi controllers at each home). For now, that's WireGuard.
The design and the network topology live in mono, under `systems/net/wireguard/edges.md`. Agents: read [AGENTS.md](AGENTS.md).

## Bootstrap a controller (once)

From the workstation, copy that controller's own crypt key (never another host's):

```sh
scp ~/.ssh/crypt.key.controller.f bemo@<controller>:.ssh/
```

On the controller, as bemo (it needs read access to the private GitHub repo):

```sh
chmod 600 ~/.ssh/crypt.key.controller.f
mkdir -p ~/gitroot && git clone git@github.com:bemowski/edges.git ~/gitroot/edges
~/gitroot/edges/wireguard/install.sh controller.f
```

`install.sh` stops the old WireGuard setup (moving it to `/root/wireguard.pre-edges-*/`), applies
this host's generated config, and enables the timers.

## Day to day

| | |
|---|---|
| change the network | edit mono `systems/net/wireguard/topology.yaml`, then `wggen check` and `wggen push` there |
| controllers pick it up | within 5 minutes (`edges-sync.timer`); `journalctl -u edges-sync` |
| apply now | `sudo systemctl start edges-sync` |
| health | `sudo bin/wg-check` |
| remove | `wireguard/uninstall.sh` |
