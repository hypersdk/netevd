# Prometheus metrics (:9091)

## Purpose

Fleet scrape for hook/event health.

```yaml
scrape_configs:
  - job_name: netevd
    static_configs:
      - targets: ['edge-01:9091']
```

## Related

[rest-api](rest-api.md) · [Workflows](../../workflows.md)
