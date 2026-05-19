<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->

# Installation

This page covers building from source, using prebuilt binaries, and common package manager installs.

## Requirements

- Linux kernel 3.10+ with netlink support
- One of: systemd-networkd, NetworkManager, or dhclient
- Build-only: Rust 1.70+, pkg-config, a C compiler

## From source (recommended)

```bash
# Install Rust toolchain (if needed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Build
git clone https://github.com/ssahani/netevd.git
cd netevd
cargo build --release

# Install binary and service
sudo install -Dm755 target/release/netevd /usr/bin/netevd
sudo install -Dm644 systemd/netevd.service /lib/systemd/system/netevd.service
sudo install -Dm644 examples/netevd.yaml /etc/netevd/netevd.yaml

# Create runtime user and directories
sudo useradd -r -M -s /usr/bin/nologin netevd || true
sudo mkdir -p /etc/netevd/{carrier.d,no-carrier.d,configured.d,degraded.d,routable.d,activated.d,disconnected.d,manager.d,routes.d}

# Start the service
sudo systemctl daemon-reload
sudo systemctl enable --now netevd
```

Notes:
- The `useradd` command may fail on some systems if the user already exists; this is safe to ignore.
- The example config installed to `/etc/netevd/netevd.yaml` should be reviewed and adapted.

## Binary releases

Download a prebuilt tarball from the GitHub releases page, extract, and install the `netevd` binary as above.

```bash
wget https://github.com/ssahani/netevd/releases/download/vX.Y.Z/netevd-x86_64-unknown-linux-gnu.tar.gz
tar xzf netevd-x86_64-unknown-linux-gnu.tar.gz
sudo install -Dm755 netevd /usr/bin/netevd
```

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
