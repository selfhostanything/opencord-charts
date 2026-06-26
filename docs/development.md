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
TimescaleDB, external Valkey-compatible cache, external Kafka, external
ScyllaDB, Vultr Object Storage, LiveKit, TURN, ingress, TLS, OTEL-ready
observability, and HPA enabled.
`single-node-values.yaml` is for evaluation and renders bundled TimescaleDB plus
Valkey. Kafka and ScyllaDB must still be provisioned separately for the current
backend architecture.

## Backend Services

The chart follows the current Rust backend split:

- `api` listens on `OPENCORD_API_ADDR` and serves HTTP API traffic.
- `realtime` listens on `OPENCORD_REALTIME_ADDR` and serves gateway traffic.
- `worker` listens on `OPENCORD_WORKER_ADDR` for health checks and background
  worker runtime.

Shared backend configuration is rendered through `opencord-config`:

```text
KAFKA_BOOTSTRAP_SERVERS
SCYLLA_CONTACT_POINTS
SCYLLA_KEYSPACE
S3_ENDPOINT
OPENCORD_LIVEKIT_URL
OPENCORD_MEDIA_REGION
OPENCORD_OTEL_ENABLED
OPENCORD_LOG_FORMAT
OPENCORD_METRICS_PROMETHEUS_ENABLED
```

`OPENCORD_MEDIA_TOKEN_TTL_SECONDS` is rendered as a direct non-secret
container env var instead of a ConfigMap key because security scanners treat any
ConfigMap key containing `TOKEN` as secret-like.

`DATABASE_URL`, `VALKEY_URL`, object storage credentials, LiveKit credentials,
TURN credentials, and app secrets are read from Kubernetes Secrets.

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
opencord-livekit: OPENCORD_LIVEKIT_API_KEY, OPENCORD_LIVEKIT_API_SECRET
opencord-turn: TURN_USERNAME, TURN_CREDENTIAL, TURN_SHARED_SECRET
opencord-app: SESSION_SECRET, SMTP_URL
```

Do not put real secret values in values files.
