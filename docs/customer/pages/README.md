# Page-by-page guides

Each guide follows: Purpose → When to use it → How to get there → Operate from the console (UX) → Related pages.

Every route is also listed in the [complete page index](../PAGE_INDEX.md).

## Cli

| Page | What it covers |
|------|----------------|
| [CLI: events](cli/events.md) | Tail normalized carrier / routable / routes / manager events. |
| [CLI: list / show](cli/list-show.md) | Inspect interfaces, routes, and rules the daemon tracks. |
| [CLI: status](cli/status.md) | Show daemon health via the REST API. |
| [CLI: validate / reload / test](cli/validate-reload.md) | Safe config checks and controlled reloads. |

## Hooks

| Page | What it covers |
|------|----------------|
| [Hook: carrier / no-carrier](hooks/carrier.md) | Run scripts when link layer goes UP (`carrier.d`) or DOWN (`no-carrier.d`). |
| [Hook: manager / NetworkManager](hooks/manager.md) | `activated.d`, `disconnected.d`, and `manager.d` cover NetworkManager device and manager state. |
| [Hook: routable](hooks/routable.md) | Fire when an interface has full L3 connectivity (systemd-networkd + dhclient paths). |
| [Hook: routes](hooks/routes.md) | React to routing table changes (`routes.d`). |

## Ops

| Page | What it covers |
|------|----------------|
| [Configuration YAML](ops/config-yaml.md) | Tune backend, monitored interfaces, policy routing list, API/metrics, filters, audit. |
| [Prometheus metrics (:9091)](ops/prometheus.md) | Fleet scrape for hook/event health. |
| [REST API (:9090)](ops/rest-api.md) | Query status, interfaces, routes, rules, and events without SSH/`ip`. |

---

11 guides. Regenerate: `node scripts/customer-docs/generate-guide-index.mjs`.
