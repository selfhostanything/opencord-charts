# OpenCord Charts

Helm charts for installing OpenCord server workloads.

## License

Apache-2.0.

## Chart

```bash
helm show chart charts/opencord
helm lint charts/opencord
scripts/validate-chart.sh
```

The `opencord` chart renders:

- API, realtime, and worker Deployments.
- API and realtime Services.
- Optional migrations Job.
- External TimescaleDB/PostgreSQL and Redis-compatible cache secrets.
- Optional bundled TimescaleDB and Valkey StatefulSets for evaluation.
- S3-compatible object storage wiring through an existing Kubernetes Secret.
- LiveKit and TURN/coturn configuration through values and existing Secrets.
- Ingress/TLS routing.
- Optional custom-domain ingress hosts through `customDomains.hosts`.
- HorizontalPodAutoscaler resources for API, realtime, and worker.

## Examples

```bash
helm template opencord charts/opencord
helm template opencord charts/opencord -f charts/opencord/examples/production-values.yaml
helm template opencord charts/opencord -f charts/opencord/examples/vultr-values.yaml
helm template opencord charts/opencord -f charts/opencord/examples/single-node-values.yaml
```

`production-values.yaml` expects external production dependencies.
`vultr-values.yaml` models OpenCord Cloud on Vultr with self-hosted external TimescaleDB, external Redis-compatible cache, Vultr Object Storage, LiveKit, TURN, ingress, TLS, and HPA enabled.
`single-node-values.yaml` is for evaluation and renders bundled TimescaleDB plus Valkey.

Custom domains can be added to the same API/realtime ingress:

```yaml
customDomains:
  enabled: true
  hosts:
    - customer.example.com
  tlsSecretName: opencord-custom-domains-tls
```

## Secrets

Production installs should create Kubernetes Secrets before installing the chart:

```text
opencord-database: DATABASE_URL
opencord-redis: REDIS_URL
opencord-s3: S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY
opencord-livekit: LIVEKIT_API_KEY, LIVEKIT_API_SECRET
opencord-turn: TURN_USERNAME, TURN_CREDENTIAL, TURN_SHARED_SECRET
opencord-app: SESSION_SECRET, SMTP_URL
```

Do not put real secret values in values files.
