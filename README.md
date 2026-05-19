# netevd

[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)
[![CI](https://github.com/ssahani/netevd/actions/workflows/ci.yml/badge.svg)](https://github.com/ssahani/netevd/actions/workflows/ci.yml)
[![Functional Tests](https://github.com/ssahani/netevd/actions/workflows/functional-tests.yml/badge.svg)](https://github.com/ssahani/netevd/actions/workflows/functional-tests.yml)
[![codecov](https://codecov.io/gh/ssahani/netevd/branch/main/graph/badge.svg)](https://codecov.io/gh/ssahani/netevd)

A small, focused network event daemon that watches Linux interfaces and runs scripts when state changes (IP, link, routes). Works with systemd-networkd, NetworkManager, or dhclient and provides policy routing, a REST API, Prometheus metrics, and secure execution of user scripts.

Table of Contents
- [Quick Start](#quick-start)
- [How it works](#how-it-works)
- [Configuration](#configuration)
- [Script directories & env](#script-directories)
- [API & Metrics](#rest-api)
- [Security](#security)
- [Contributing & License](#contributing)

## Quick Start

Minimal steps to run on a Linux machine (recommended: systemd systems):

1. Build and install

```bash
git clone https://github.com/ssahani/netevd.git && cd netevd
cargo build --release
sudo install -Dm755 target/release/netevd /usr/bin/netevd
sudo install -Dm644 systemd/netevd.service /lib/systemd/system/netevd.service
sudo install -Dm644 examples/netevd.yaml /etc/netevd/netevd.yaml
```

2. Create user, directories, and start

```bash
sudo useradd -r -M -s /usr/bin/nologin netevd
sudo mkdir -p /etc/netevd/{carrier.d,no-carrier.d,configured.d,degraded.d,routable.d,activated.d,disconnected.d,manager.d,routes.d}
sudo systemctl daemon-reload
sudo systemctl enable --now netevd
```

3. Example script (runs when an interface becomes routable):

```bash
sudo tee /etc/netevd/routable.d/01-notify.sh > /dev/null <<'EOF'
#!/bin/bash
logger -t netevd "Interface $LINK is routable: $ADDRESSES"
EOF
sudo chmod +x /etc/netevd/routable.d/01-notify.sh
```

See docs/QUICKSTART.md for a full walkthrough and examples/ for sample configs.

## How it works

netevd subscribes to kernel netlink events and backend signals (systemd-networkd, NetworkManager) and keeps a centralized NetworkState.
On state changes it updates policy routing, runs scripts from event directories, and optionally exposes state via a REST API.

## Configuration

Configuration lives at /etc/netevd/netevd.yaml. Example:

```yaml
system:
  log_level: "info"
  backend: "systemd-networkd"

monitoring:
  interfaces: []          # empty = monitor all

routing:
  policy_rules: []        # interfaces that get automatic policy routing

backends:
  systemd_networkd:
    emit_json: true
  dhclient:
    use_dns: false
    use_domain: false
    use_hostname: false
  networkmanager: {}
```

Full reference: CONFIGURATION.md

## Script directories

Scripts live under /etc/netevd and are organized by event (e.g., routable.d, carrier.d). They run in alphabetical order; use numeric prefixes to control ordering. Scripts receive environment variables such as $LINK, $LINKINDEX, $STATE, $BACKEND, and $ADDRESSES. systemd-networkd also provides $JSON when emit_json is enabled.

## REST API

HTTP endpoints (Axum):

- GET /api/v1/status
- GET /api/v1/interfaces
- GET /api/v1/routes
- GET /api/v1/events
- GET /metrics (Prometheus)

See docs/API.md for details.

## Security

netevd runs with minimal privileges: drops to a dedicated netevd user, keeps only CAP_NET_ADMIN, validates inputs, and executes scripts without a shell intermediary. See SECURITY.md for the threat model and hardening recommendations.

## Contributing

Build, test, lint:

```bash
cargo build && cargo test && cargo clippy -- -D warnings
```

Contributions welcome — see CONTRIBUTING.md.

## License

LGPL-3.0-or-later — (c) 2026 Susant Sahani <ssahani@redhat.com>
