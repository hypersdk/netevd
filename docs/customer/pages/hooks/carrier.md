# Hook: carrier / no-carrier

## Purpose

Run scripts when link layer goes UP (`carrier.d`) or DOWN (`no-carrier.d`).

## When to use it

Cable plug / Wi‑Fi associate notifications. **Not** for “has an IP yet” — use `routable.d` for L3.

## How to get there

```bash
sudo install -m755 myscript.sh /etc/netevd/carrier.d/10-log.sh
```

## What you can do

- Log or notify on link flaps
- Combine with `$LINK` / `$BACKEND`

## Related

[routable](routable.md) · [Admin basics](../../admin-basics.md)
