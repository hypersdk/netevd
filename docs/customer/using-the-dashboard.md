# Using the operator surfaces

netevd has **no browser console**. Day-2 work uses hooks, the CLI, REST/Prometheus, and journals.

## Mental model

```text
Kernel / managers  →  netevd watchers  →  NetworkState
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
           hooks.d/*      REST :9090     metrics :9091
              │               │
              ▼               ▼
         your scripts     netevd status/list/events
```

## Where to look

| Surface | Role |
|---------|------|
| `/etc/netevd/*.d/` | Event scripts (primary UX) |
| `/etc/netevd/netevd.yaml` | Backend, filters, API bind, metrics |
| `netevd status\|list\|show\|events` | Live inspection via API |
| `journalctl -u netevd` | Daemon + hook exit logs |
| `:9090` / `:9091` | Fleet scrape / status |

## Tips

1. Start with one `routable.d` logger before complex automation.
2. Use `netevd events -f` while bouncing a link to confirm events.
3. On multi-homed hosts, confirm policy rules with `netevd list rules` or `ip rule`.
4. Keep hooks small and executable; non-zero exits are logged and do not stop other scripts.

Next: [Page-by-page guides](pages/README.md) · [Workflows](workflows.md)
