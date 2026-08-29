# netevd — Customer Documentation

**netevd** is a Netlink-first Linux network event daemon (Rust). It watches carrier, address, route, and manager state — then runs your scripts with rich context. It also maintains per-interface policy routing on multi-homed hosts and exposes REST + Prometheus on `:9090` / `:9091`.

| You want to… | Open |
|--------------|------|
| Install and fire the first hook | [Getting Started](getting-started.md) |
| Orient around hooks / CLI / API | [Using the Dashboard](using-the-dashboard.md) |
| Screen-by-screen / command guides | [Page-by-page guides](pages/README.md) |
| Look up hooks and CLI | [Complete page index](PAGE_INDEX.md) |
| YAML, systemd, ports, security | [Admin basics](admin-basics.md) |
| Multi-home, resume, observe | [Common workflows](workflows.md) |

**→ [Docs one-pager](/docs/netevd)** · **[GitHub](https://github.com/zyvorai/netevd)** · **[netctl](/docs/netctl)**

## Printable PDFs

```bash
node scripts/customer-docs/build-customer-pdfs.mjs
```

Output lands in [`pdf/`](pdf/):

- `netevd-Customer-README.pdf`
- `netevd-Getting-Started.pdf`
- `netevd-Page-by-Page.pdf`
- `netevd-Admin-Basics.pdf`

## Product at a glance

```text
  Hooks      →  /etc/netevd/{carrier,routable,routes,…}.d/
  Config     →  /etc/netevd/netevd.yaml
  REST/API   →  :9090  (default bind 127.0.0.1)
  Metrics    →  :9091
  Unit       →  netevd.service
```

---

*Zyvor · [zyvor.dev](https://zyvor.dev) · netevd · Apache-2.0*
