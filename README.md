# OpenCord Charts

Helm charts for installing OpenCord server workloads.

## License

Apache-2.0.

## Validate

```bash
helm lint charts/opencord
helm template opencord charts/opencord
```

The Phase 00 chart templates API, realtime, worker, services, config, and an optional migrations Job. Production dependency wiring remains explicit through existing Kubernetes secrets.
