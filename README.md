<p align="center">
  <a href="https://zyvor.dev/?utm_source=github&utm_medium=netevd">
    <img src="docs/img/zyvor-logo.webp" alt="Zyvor AI Labs — HyperSDK Platform" width="220">
  </a>
</p>

<p align="center"><sub>Linux network events · Policy routing · Part of the HyperSDK networking stack by Zyvor AI Labs</sub></p>

# netevd

[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)
[![CI](https://github.com/hypersdk/netevd/actions/workflows/ci.yml/badge.svg)](https://github.com/hypersdk/netevd/actions/workflows/ci.yml)
[![Functional Tests](https://github.com/hypersdk/netevd/actions/workflows/functional-tests.yml/badge.svg)](https://github.com/hypersdk/netevd/actions/workflows/functional-tests.yml)
[![codecov](https://codecov.io/gh/hypersdk/netevd/branch/main/graph/badge.svg)](https://codecov.io/gh/hypersdk/netevd)

**netevd** is a network event daemon that watches your Linux network interfaces and runs scripts when things change. Think of it as systemd path units, but purpose-built for networking: when an interface gets an IP, loses its link, or routes change, netevd executes your scripts with full context about what happened.

It bridges **systemd-networkd**, **NetworkManager**, and **dhclient** into a single, unified event system -- with automatic policy routing, a REST API, Prometheus metrics, and a defense-in-depth security model.

> **Enterprise & production:** [zyvor.dev](https://zyvor.dev/?utm_source=github&utm_medium=netevd) · [Contact sales](https://zyvor.dev/contact?utm_source=github&utm_medium=netevd) · [sales@zyvor.dev](mailto:sales@zyvor.dev)

## Why netevd?

| Problem | netevd solution |
|---------|----------------|
| Need scripts to run when network state changes | Drop scripts in `/etc/netevd/routable.d/` -- done |
| Multi-homed server with broken return-path routing | Automatic per-interface routing tables and policy rules |
| Want real-time network events, not polling | Netlink multicast: sub-100ms latency, zero polling |
| Need to support multiple network managers | One daemon handles networkd, NetworkManager, and dhclient |
| Security concerns with network daemons | Privilege separation, CAP_NET_ADMIN only, input validation |

## Quick Start

### GitHub Release (recommended)

```bash
curl -LO https://github.com/hypersdk/netevd/releases/download/v0.2.3/netevd-0.2.3-linux-amd64.tar.gz
tar xzf netevd-*-linux-amd64.tar.gz && cd netevd-*-linux-amd64
sudo ./install.sh
sudo systemctl enable --now netevd
```

See [INSTALL.md](INSTALL.md) for arm64, source builds, and package managers.

### First hook script

Create your first script — this runs whenever an interface becomes fully routable:

```bash
cat <<'EOF' | sudo tee /etc/netevd/routable.d/01-notify.sh && sudo chmod +x /etc/netevd/routable.d/01-notify.sh
#!/bin/bash
logger -t netevd "Interface $LINK is routable: $ADDRESSES"
EOF
```

For the full walkthrough, see the **[Quick Start Guide](docs/QUICKSTART.md)**.

## How It Works

```
                    +------------------+
                    |   Linux Kernel   |
                    |  Netlink events  |
                    +--------+---------+
                             |
         +-------------------+-------------------+
         |                   |                   |
   +-----------+      +-----------+      +-----------+
   | Addresses |      |   Links   |      |  Routes   |
   |  watcher  |      |  watcher  |      |  watcher  |
   +-----+-----+      +-----+-----+      +-----+-----+
         |                   |                   |
         +-------------------+-------------------+
                             |
                    +--------+---------+
                    |  NetworkState    |
                    |  (Arc<RwLock>)   |
                    +--------+---------+
                             |
              +--------------+--------------+
              |              |              |
        +-----+-----+  +----+----+  +------+------+
        |  Routing   |  | Script  |  |    DBus     |
        |  policy    |  |  exec   |  |  resolved/  |
        |  rules     |  |         |  |  hostnamed  |
        +------------+  +---------+  +-------------+
```

**Event sources** -- netevd subscribes to kernel netlink multicast groups and listens for DBus signals from your chosen backend (systemd-networkd, NetworkManager) or watches dhclient lease files via inotify.

**State management** -- All state is held in a single `NetworkState` behind `Arc<RwLock>`, updated by concurrent Tokio tasks. Read locks for queries, write locks for mutations -- no races.

**Actions** -- On state changes, netevd configures routing policy rules, executes scripts from the matching event directory, and optionally pushes DNS/hostname updates via DBus.

## Configuration

```yaml
# /etc/netevd/netevd.yaml
system:
  log_level: "info"
  backend: "systemd-networkd"    # or "NetworkManager" or "dhclient"

monitoring:
  interfaces:                    # empty = monitor all
    - eth0
    - eth1

routing:
  policy_rules:                  # auto-create per-interface routing tables
    - eth1

backends:
  systemd_networkd:
    emit_json: true              # pass full JSON to scripts via $JSON
  dhclient:
    use_dns: false
    use_domain: false
    use_hostname: false
  networkmanager: {}
```

Full reference: **[Configuration Guide](CONFIGURATION.md)**

## Script Directories

Scripts are organized by the event that triggers them:

| Directory | Trigger | Backends |
|-----------|---------|----------|
| `carrier.d/` | Cable connected | All |
| `no-carrier.d/` | Cable disconnected | All |
| `configured.d/` | Interface has IP | systemd-networkd |
| `degraded.d/` | Partial configuration | systemd-networkd |
| `routable.d/` | Full connectivity | systemd-networkd, dhclient |
| `activated.d/` | Device activated | NetworkManager |
| `disconnected.d/` | Device disconnected | NetworkManager |
| `manager.d/` | Manager state change | All |
| `routes.d/` | Routing table change | All |

Scripts run in alphabetical order. Use numeric prefixes (`01-`, `02-`) to control ordering. Non-zero exit codes are logged but don't block other scripts.

### Environment Variables

Every script receives:

| Variable | Example |
|----------|---------|
| `$LINK` | `eth0` |
| `$LINKINDEX` | `2` |
| `$STATE` | `routable` |
| `$BACKEND` | `systemd-networkd` |
| `$ADDRESSES` | `192.168.1.100 10.0.0.5` |

**systemd-networkd** adds `$JSON` with full interface data (MTU, driver, DNS, routes).
**dhclient** adds `$DHCP_ADDRESS`, `$DHCP_GATEWAY`, `$DHCP_DNS`, `$DHCP_DOMAIN`, `$DHCP_HOSTNAME`.

## Automatic Policy Routing

For multi-homed servers, netevd solves the classic "wrong interface" problem automatically. When you list an interface under `routing.policy_rules`, netevd:

1. Creates a custom routing table (ID = 200 + interface index)
2. Adds `from <ip> lookup <table>` and `to <ip> lookup <table>` rules
3. Installs a default route via the interface's gateway in that table
4. Cleans up automatically when addresses are removed

```bash
# After netevd configures eth1 (index 3, IP 192.168.1.100):
$ ip rule list
32765: from 192.168.1.100 lookup 203
32766: to 192.168.1.100 lookup 203

$ ip route show table 203
default via 192.168.1.1 dev eth1
```

## Security

netevd follows a defense-in-depth model:

1. **Privilege separation** -- Starts as root, immediately drops to the `netevd` user via `setuid`/`setgid`
2. **Minimal capabilities** -- Retains only `CAP_NET_ADMIN`; child processes inherit nothing
3. **Input validation** -- All external data (interface names, IPs, hostnames) is validated; shell metacharacters are rejected
4. **No shell intermediary** -- Scripts are executed directly, not via `sh -c`
5. **systemd hardening** -- `NoNewPrivileges`, `ProtectSystem=strict`, `PrivateTmp`

Details: **[Security Policy](SECURITY.md)**

## Performance

| Metric | Value |
|--------|-------|
| Memory (idle) | 3-5 MB RSS |
| CPU (idle) | < 1% |
| Event latency | < 100ms (netlink multicast) |
| Event-to-script | < 10ms |
| Throughput | 1000+ events/sec |

## REST API

9 endpoints built on Axum for remote management and monitoring:

```bash
curl http://localhost:9090/api/v1/status       # Daemon status
curl http://localhost:9090/api/v1/interfaces    # List interfaces
curl http://localhost:9090/api/v1/routes        # Routing table
curl http://localhost:9090/api/v1/events        # Event history
curl http://localhost:9090/metrics              # Prometheus metrics
curl http://localhost:9090/health               # Health check
```

REST API and metrics are exposed on the daemon HTTP port (default `9090`); see [Configuration](CONFIGURATION.md) for endpoints and options.

## Documentation

| Guide | Description |
|-------|-------------|
| **[Quick Start](docs/QUICKSTART.md)** | Up and running in 5 minutes |
| **[Installation](INSTALL.md)** | All platforms and package managers |
| **[Configuration](CONFIGURATION.md)** | Complete YAML reference |
| **[Security](SECURITY.md)** | Threat model and hardening |
| **[Contributing](CONTRIBUTING.md)** | Dev setup and PR guidelines |
| **[Changelog](CHANGELOG.md)** | Release history |
| **[Enterprise](docs/zyvor-enterprise.md)** | Zyvor contact & platform |
| **[CE vs Enterprise](docs/ce-vs-enterprise.md)** | Open source vs production |

## Contributing

```bash
git clone https://github.com/hypersdk/netevd.git && cd netevd
cargo build && cargo test && cargo clippy -- -D warnings
```

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the full guide.

## Support

<p align="center">
  <a href="https://zyvor.dev/">
    <img src="docs/img/zyvor-logo.webp" alt="Zyvor AI Labs" width="220">
  </a>
</p>

**netevd** is the open-source network event daemon in the [HyperSDK Platform](https://zyvor.dev/) (Zeus suite), engineered by [Zyvor AI Labs](https://zyvor.dev/).

### Open source (this repository)

- **GitHub Issues**: [Report bugs](https://github.com/hypersdk/netevd/issues)
- **Documentation**: [docs/](docs/)

### Enterprise — approach [zyvor.dev](https://zyvor.dev/)

**Production workloads, SLAs, and platform integration are provided by Zyvor — not via GitHub Issues.**

| | |
|---|---|
| **Platform** | **[zyvor.dev](https://zyvor.dev/)** |
| **Sales & demos** | [sales@zyvor.dev](mailto:sales@zyvor.dev) |
| **General inquiries** | [info@zyvor.dev](mailto:info@zyvor.dev) |
| **Contact form** | [zyvor.dev/contact](https://zyvor.dev/contact) |

#### Related networking products

| Product | Focus |
|---------|--------|
| **[netevd](https://github.com/hypersdk/netevd)** (this repo) | Event hooks, policy routing, metrics |
| **[netctl](https://github.com/hypersdk/netctl)** | Network configuration CLI |
| **[cloud-netconfig](https://github.com/hypersdk/cloud-netconfig)** | Cloud metadata networking |
| **[PacketWolf](https://zyvor.dev/packetwolf)** | eBPF observability |
| **[HyperSDK Platform](https://zyvor.dev/hypersdk)** | VM export & migration |

→ [Watch demo](https://zyvor.dev/demo?utm_source=github&utm_medium=netevd) · [Compare products](https://zyvor.dev/docs/products) · [Contact sales](https://zyvor.dev/contact?utm_source=github&utm_medium=netevd)

📄 [Open source vs Enterprise](docs/ce-vs-enterprise.md) · [Enterprise guide](docs/zyvor-enterprise.md)

### Security

Report vulnerabilities privately using [SECURITY.md](SECURITY.md).

## License

[LGPL-3.0-or-later](https://www.gnu.org/licenses/lgpl-3.0.html) -- Copyright 2026 Susant Sahani <<ssahani@redhat.com>>
