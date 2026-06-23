# Chart Development

This repository contains the Helm chart for OpenCord server workloads.

## Chart Checks

```bash
helm show chart charts/opencord
helm lint charts/opencord
scripts/validate-chart.sh
```

## Render Examples

```bash
helm template opencord charts/opencord
helm template opencord charts/opencord -f charts/opencord/examples/production-values.yaml
helm template opencord charts/opencord -f charts/opencord/examples/vultr-values.yaml
helm template opencord charts/opencord -f charts/opencord/examples/single-node-values.yaml
```

`production-values.yaml` expects external production dependencies.
`vultr-values.yaml` models OpenCord Cloud on Vultr with self-hosted external
TimescaleDB, external Valkey-compatible cache, Vultr Object Storage, LiveKit,
TURN, ingress, TLS, and HPA enabled.
`single-node-values.yaml` is for evaluation and renders bundled TimescaleDB plus
Valkey.

## Custom Domains

Custom domains can be added to the same API/realtime ingress:

```yaml
customDomains:
  enabled: true
  hosts:
    - customer.example.com
  tlsSecretName: opencord-custom-domains-tls
```

Self-hosted servers allow browser CORS only from `opencord.publicUrl` by
default. Add the official hosted web client origin or other trusted origins
explicitly:

```yaml
opencord:
  allowedOrigins:
    - https://app.opencord.example.com
```

## Secrets

Production installs should create Kubernetes Secrets before installing the
chart:

```text
opencord-database: DATABASE_URL
opencord-valkey: VALKEY_URL
opencord-s3: S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY
opencord-livekit: LIVEKIT_API_KEY, LIVEKIT_API_SECRET
opencord-turn: TURN_USERNAME, TURN_CREDENTIAL, TURN_SHARED_SECRET
opencord-app: SESSION_SECRET, SMTP_URL
```

Do not put real secret values in values files.
