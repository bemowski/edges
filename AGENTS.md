# AGENTS.md: edges

Instructions for AI coding agents working in this repo. Humans: the same rules apply.

## What this repo is

What runs on the edge machines: the Raspberry Pi controllers at each home (`controller.f`,
`controller.m`, `controller.b`). Each controller clones this repo (private, on GitHub) as `bemo`
and polls it GitOps style: `edges-sync.timer` fast-forwards to `origin/main`
and applies that host's config. For now that is only WireGuard.

The design, the network topology, and the generator live in the **mono** repo, under
`systems/net/wireguard/` (start with `edges.md`). That is also where the bulk of the documentation lives.

## Layout

| path | what | who edits |
|---|---|---|
| `bin/` | scripts shared by every edge: `edges-sync` (poller), `wg-apply`, `wg-reresolve`, `wg-check`, `encrypt`/`decrypt` + `pylib/` (copied from mono `systems/common/bin`) | by hand |
| `wireguard/install.sh`, `uninstall.sh`, `teardown-legacy.sh` | one-time setup on a controller | by hand |
| `wireguard/common/` | systemd units, sysctl drop-in | by hand |
| `wireguard/hosts/**` | **generated** by mono `wggen push`: per-controller configs, each encrypted with that controller's key, plus `manifest.json` | **never by hand** |

## Rules

- **Never edit `wireguard/hosts/`.** To change the network, edit mono `systems/net/wireguard/topology.yaml`
  and run `wggen check` there. The human runs `wggen push`.
- **No plaintext secrets, anywhere.** No private key, preshared key, `crypt.key*` or decrypted
  `.conf` is ever written into this repo (`.gitignore` backs this up). On a controller, `wg-apply`
  decrypts in memory and writes only to `/etc/wireguard` (mode 600).
- **One key per host.** A controller holds only its own `crypt.key.<controller>`. Never encrypt one
  host's material with another host's key.
- **Don't force-push `main`.** Controllers only fast-forward; a rewritten `main` stops their updates.
- **Who does what.** Agents edit files and check them: `mise run check` (`sh -n`, Python compile, a
  dry-run `wg-apply`). The human runs anything on a controller, and commits and pushes.
  Agents don't run `sudo`, ssh to the edges, commit, or push.
- **Scripts:** keep shell scripts `#!/bin/sh` with `set -e`, idempotent, using `sudo` themselves
  where they need it. Python needs only the standard library (the Pis use the system `python3`).
- **Changes to `bin/` run as root on every controller** within 5 minutes of being pushed. Keep them
  small, and test with `bin/wg-apply --root <dir>` first.
