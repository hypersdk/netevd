# Common workflows

## A. First routable notify

1. Install and start `netevd`.
2. Drop an executable script in `/etc/netevd/routable.d/`.
3. Bounce the interface or renew DHCP.
4. Confirm `journalctl -u netevd` and `logger` / script side effects.

## B. Multi-homed policy routing

1. List secondary interfaces under `routing.policy_rules` in YAML (or rely on defaults for monitored links).
2. Acquire addresses on each uplink.
3. Verify:

```bash
netevd list rules
ip rule list
ip route show table $((200 + ifindex))
```

Traffic sourced from an address on `eth1` should leave via `eth1`'s gateway.

## C. Watch events live

```bash
netevd events -f
# or filter:
netevd events -f -i eth0 -t routable
```

## D. Fleet observability

1. Set `api.bind_address: "0.0.0.0"` only on trusted networks (or scrape via localhost exporter).
2. Point Prometheus at `:9091` (metrics) and/or use REST `:9090` for status.
3. Alert when hook execution counters go quiet (daemon likely down).

## E. Safe change window

```bash
netevd validate -c /etc/netevd/netevd.yaml
sudo systemctl reload netevd   # or netevd reload if API reload is enabled
journalctl -u netevd -n 50 --no-pager
```

## F. Ignore noisy interfaces

Add a YAML filter with `action: ignore` for `docker*`, `veth*`, etc. (see example config).
