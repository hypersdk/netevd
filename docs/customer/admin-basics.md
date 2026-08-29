# Admin basics

| Topic | Detail |
|-------|--------|
| Config | `/etc/netevd/netevd.yaml` (see `config/netevd.example.yaml`) |
| Hooks | `/etc/netevd/{carrier,no-carrier,configured,degraded,routable,activated,disconnected,manager,routes}.d/` |
| Unit | `netevd.service` — `systemctl enable --now netevd` |
| Logs | `journalctl -u netevd -f` |
| REST | `api.bind_address` + `api.port` (default `127.0.0.1:9090`) |
| Metrics | `metrics.port` (default `9091`) |
| Backend | `system.backend`: `systemd-networkd` · `NetworkManager` · `dhclient` |
| Privilege | Drops to `netevd` user; retains `CAP_NET_ADMIN`; hooks inherit no caps |
| Dry-run | `netevd --dry-run …` skips script execution / mutations |
| Validate | `netevd validate` against the config file |
| Reload | `netevd reload` (API) after config/hook changes when supported |
| Security | See repo `SECURITY.md`; restrict YAML permissions |

## Hook environment (common)

| Variable | Content |
|----------|---------|
| `$LINK` | Interface name |
| `$LINKINDEX` | Kernel ifindex |
| `$STATE` | Normalized event state |
| `$BACKEND` | Source backend |
| `$ADDRESSES` | Address / gateway / DNS summary |
| `$JSON` | Full payload (systemd-networkd when enabled) |
| `$DHCP_*` | dhclient lease fields |

## Support

[GitHub issues](https://github.com/zyvorai/netevd/issues) · [Contact Zyvor](/contact) for Enterprise
