# Configuration YAML

## Purpose

Tune backend, monitored interfaces, policy routing list, API/metrics, filters, audit.

Path: `/etc/netevd/netevd.yaml` — start from `config/netevd.example.yaml`.

## Highlights

- `system.backend` — systemd-networkd | NetworkManager | dhclient
- `routing.policy_rules` — interfaces getting custom tables
- `filters` — execute / ignore / log by interface pattern or event
- `api` / `metrics` — bind and ports

## Related

[Admin basics](../../admin-basics.md) · [validate-reload](../cli/validate-reload.md)
