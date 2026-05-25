<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->

# Installation

This page covers building from source, using prebuilt binaries, and common package manager installs.

## Requirements

- Linux kernel 3.10+ with netlink support
- One of: systemd-networkd, NetworkManager, or dhclient
- Build-only: Rust 1.70+, pkg-config, a C compiler

## From source

```bash
git clone https://github.com/hypersdk/netevd.git
cd netevd
cargo build --release

sudo install -Dm755 target/release/netevd /usr/bin/netevd
sudo install -Dm644 systemd/netevd.service /lib/systemd/system/netevd.service
sudo install -Dm644 examples/netevd.yaml /etc/netevd/netevd.yaml

sudo useradd -r -M -s /usr/bin/nologin netevd || true
sudo mkdir -p /etc/netevd/{carrier.d,no-carrier.d,configured.d,degraded.d,routable.d,activated.d,disconnected.d,manager.d,routes.d}

sudo systemctl daemon-reload
sudo systemctl enable --now netevd
```

Notes:
- The `useradd` command may fail on some systems if the user already exists; this is safe to ignore.
- The example config installed to `/etc/netevd/netevd.yaml` should be reviewed and adapted.

## Binary releases (GitHub)

Download a customer bundle from [Releases](https://github.com/hypersdk/netevd/releases):

```bash
curl -LO https://github.com/hypersdk/netevd/releases/download/v0.2.2/netevd-0.2.2-linux-amd64.tar.gz
tar xzf netevd-*-linux-amd64.tar.gz && cd netevd-*-linux-amd64
sudo ./install.sh
sudo systemctl enable --now netevd
```

Arm64: `netevd-0.2.2-linux-arm64.tar.gz`. Each tarball includes `install.sh`, systemd unit, and sample config.

## Package managers

Where available, prefer distro packages. Examples:

- crates.io: `cargo install netevd`
- Arch (AUR): `yay -S netevd`
- Fedora/RHEL: `sudo dnf install netevd-X.Y.Z-1.x86_64.rpm`
- Debian/Ubuntu: `sudo dpkg -i netevd_X.Y.Z_amd64.deb && sudo apt-get install -f`

## Post-install checklist

- Verify the backend (systemd-networkd/NetworkManager/dhclient) is running.
- Review `/etc/netevd/netevd.yaml` and adjust `system.backend` and `routing.policy_rules` as needed.
- Ensure scripts under `/etc/netevd/*.d/` are executable.

## Verify

```bash
sudo systemctl status netevd
sudo journalctl -u netevd -f
netevd --version
```

## Upgrade & uninstall

Follow the same install steps to upgrade (build/install new binary and restart service). To uninstall:

```bash
sudo systemctl stop netevd && sudo systemctl disable netevd
sudo rm -f /usr/bin/netevd /lib/systemd/system/netevd.service
sudo systemctl daemon-reload
sudo userdel netevd || true
sudo mv /etc/netevd /etc/netevd.backup || true
```

## Troubleshooting

If the service fails to start:

```bash
sudo systemctl status netevd -l
sudo journalctl -u netevd -n 200 --no-pager
```

Common causes: missing `netevd` user, YAML syntax error in `/etc/netevd/netevd.yaml`, missing capabilities. See docs/TROUBLESHOOTING.md for guidance.
