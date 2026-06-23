# OpenCord Charts

OpenCord Charts provides the Helm chart for running OpenCord server workloads
on Kubernetes.

Use this repository when you want to install or operate OpenCord with
Kubernetes-native primitives instead of a single Docker Compose stack.

## What It Deploys

The `opencord` chart renders:

- API, realtime, and worker Deployments.
- API and realtime Services.
- Optional migration Job.
- Ingress and TLS routing.
- HorizontalPodAutoscaler resources.
- External TimescaleDB/PostgreSQL and Valkey-compatible cache wiring.
- S3-compatible object storage configuration.
- LiveKit and TURN/coturn configuration.
- Optional bundled TimescaleDB and Valkey for evaluation installs.
- Custom-domain ingress hosts for customer domains.

Production installs should use external database, cache, media, and object
storage services. Bundled dependencies are intended for evaluation only.

## Quick Start

```bash
helm template opencord charts/opencord
scripts/validate-chart.sh
```

## Repository

```text
charts/opencord     OpenCord Helm chart
scripts/            Local chart validation helpers
docs/               Chart development notes
```

Development commands, example values, custom-domain notes, and required
Kubernetes Secrets live in [docs/development.md](docs/development.md).

## License

Apache-2.0
