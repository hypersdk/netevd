# Hook: routable

## Purpose

Fire when an interface has full L3 connectivity (systemd-networkd + dhclient paths).

## When to use it

Start dependent services, register DNS, notify when `$ADDRESSES` is meaningful.

## How to get there

`/etc/netevd/routable.d/` — executable scripts, lexical order.

## What you can do

- Read `$ADDRESSES`, `$JSON` (networkd), `$DHCP_*` (dhclient)
- Branch on `$BACKEND`

## Related

[carrier](carrier.md) · [Workflows](../../workflows.md)
