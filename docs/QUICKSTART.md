<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->

# Quick Start

Get netevd running quickly. These minimal steps use systemd; adapt for other init systems.

Table of Contents
- [Install](#install)
- [Create runtime user & dirs](#create-runtime-user--dirs)
- [Example script](#example-script)
- [Start & verify](#start--verify)
- [Variables for scripts](#variables-for-scripts)
- [Debugging](#debugging)

## Install

From source (recommended):

```bash
# Install Rust toolchain (if needed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Build and install
git clone https://github.com/ssahani/netevd.git && cd netevd
cargo build --release
sudo install -Dm755 target/release/netevd /usr/bin/netevd
sudo install -Dm644 systemd/netevd.service /lib/systemd/system/netevd.service
sudo install -Dm644 examples/netevd.yaml /etc/netevd/netevd.yaml
```

Or install from your distro packages when available.

## Create runtime user & dirs

```bash
# Create a non-login runtime user (safe to ignore if user exists)
sudo useradd -r -M -s /usr/bin/nologin netevd || true

# Create event directories
sudo mkdir -p /etc/netevd/{carrier.d,no-carrier.d,configured.d,degraded.d,routable.d,activated.d,disconnected.d,manager.d,routes.d}
```

## Example script

Create a simple notification script that runs when an interface becomes routable:

```bash
sudo tee /etc/netevd/routable.d/01-notify.sh > /dev/null <<'EOF'
#!/bin/bash
logger -t netevd "Interface $LINK is routable: $ADDRESSES"
EOF
sudo chmod +x /etc/netevd/routable.d/01-notify.sh
```

## Start & verify

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now netevd
sudo systemctl status netevd

# Trigger a link event (replace eth0 with a real interface)
sudo ip link set eth0 down && sudo ip link set eth0 up

# Check logs for your script
sudo journalctl -t netevd -n 50 --no-pager
```

## Variables for scripts

Scripts receive environment variables; common ones include:

- `LINK` — interface name (e.g., `eth0`)
- `LINKINDEX` — kernel interface index
- `STATE` — event state (e.g., `routable`)
- `BACKEND` — event backend (e.g., `systemd-networkd`)
- `ADDRESSES` — space-separated IPs
- `JSON` — full interface JSON (systemd-networkd if enabled)

## Debugging

Follow logs and test scripts manually:

```bash
sudo journalctl -u netevd -f
sudo env LINK=eth0 LINKINDEX=2 STATE=routable ADDRESSES="192.168.1.100" /etc/netevd/routable.d/01-notify.sh
```

## Next steps

- See the configuration reference: ../CONFIGURATION.md
- Browse real-world examples: EXAMPLES.md
- API docs: API.md
- Metrics: METRICS.md
- Troubleshooting: TROUBLESHOOTING.md
