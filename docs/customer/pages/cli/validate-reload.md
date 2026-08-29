# CLI: validate / reload / test

## Purpose

Safe config checks and controlled reloads.

```bash
netevd validate -c /etc/netevd/netevd.yaml
netevd reload --endpoint http://127.0.0.1:9090
netevd test   # see --help for dry-run style checks
netevd version --detailed
```

Global flags: `--dry-run`, `-v`, `-c /path/to/netevd.yaml`.

## Related

[config-yaml](../ops/config-yaml.md) · [Admin basics](../../admin-basics.md)
