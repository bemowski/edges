# edges

What runs on the edge machines (the Raspberry Pi controllers at each home). For now, that's WireGuard.
The design and the network topology live in mono, under `systems/net/wireguard/edges.md`. Agents: read [AGENTS.md](AGENTS.md).

## Bootstrap a controller (once)

On the workstation, in mono `systems/net/wireguard`: have the controller make its own WireGuard key
(`/etc/edges/wg.key`, never leaves the box; asks for its sudo password) and record the public key:

```sh
wggen enroll controller.f <ssh-host>     # writes keys/controller.f.pub; commit it
wggen check && wggen push
```

On the controller, as bemo (it needs read access to the private GitHub repo):

```sh
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
