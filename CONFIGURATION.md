<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->

# Configuration Reference

Configuration is read from `/etc/netevd/netevd.yaml`. Most changes require restarting the service: `sudo systemctl restart netevd`.

## Example

```yaml
system:
  log_level: "info"
  backend: "systemd-networkd"

monitoring:
  interfaces: []        # empty = monitor all

routing:
  policy_rules: []      # interfaces that receive automatic policy routing

backends:
  systemd_networkd:
    emit_json: true
  dhclient:
    use_dns: false
    use_domain: false
    use_hostname: false
  networkmanager: {}
```

## system

### log_level

Controls logging verbosity. Use `info` or `warn` in production; use `debug`/`trace` when diagnosing problems.

Values: `trace`, `debug`, `info`, `warn`, `error` (default: `info`).

Runtime override example: `RUST_LOG=debug sudo systemctl restart netevd`

### backend

Which backend to listen to for events. Valid values: `systemd-networkd`, `NetworkManager`, `dhclient`. Default: `systemd-networkd`.

## monitoring

### interfaces

List of interface names to watch. An empty list monitors all interfaces.

Type: array of strings. Example:

```yaml
monitoring:
  interfaces:
    - eth0
    - wlan0
```

## routing

### policy_rules

Interfaces listed here will get automatic, per-interface policy routing to preserve correct return-path behavior on multi-homed hosts.

Type: array of strings. Example:

```yaml
routing:
  policy_rules:
    - eth1
    - eth2
```

Behavior: For each interface, netevd creates a routing table (ID = 200 + interface index), installs `from`/`to` rules, and adds a default route in that table. Rules are removed when addresses are deleted.

## backends

### systemd_networkd

`emit_json` (boolean, default: true) controls whether full interface data is passed to scripts via the `$JSON` environment variable. Disable to save a small amount of overhead if scripts don't use `$JSON`.

### dhclient

- `use_dns` (bool): Send DHCP DNS to systemd-resolved (requires systemd-resolved).
- `use_domain` (bool): Send DHCP domain to systemd-resolved.
- `use_hostname` (bool): Send DHCP hostname to systemd-hostnamed (this will change the system hostname).

### networkmanager

No options currently.

## Script directories

Scripts live under `/etc/netevd/` in event-specific directories, e.g. `routable.d`, `carrier.d`, etc. They must be executable and begin with a shebang. Scripts run alphabetically; use numeric prefixes to control ordering.

## Environment variables

All scripts receive common variables:

- `LINK` — interface name (e.g., `eth0`)
- `LINKINDEX` — interface index
- `STATE` — current state (e.g., `routable`)
- `BACKEND` — event backend (e.g., `systemd-networkd`)
- `ADDRESSES` — space-separated IP addresses

When `emit_json: true`, systemd-networkd also provides `JSON` with full interface data. dhclient provides `DHCP_*` variables when applicable.

## Validation

Quick checks:

```bash
# YAML syntax
yamllint /etc/netevd/netevd.yaml

# Python-based validation
python3 -c "import yaml; yaml.safe_load(open('/etc/netevd/netevd.yaml'))"

# If the binary supports it
sudo netevd --config /etc/netevd/netevd.yaml --validate || true
```

## See also

- Quick Start: docs/QUICKSTART.md
- Examples: docs/EXAMPLES.md
- Troubleshooting: docs/TROUBLESHOOTING.md
