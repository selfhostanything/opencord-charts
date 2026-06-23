# AGENTS.md

Rules for agents working in `opencord-charts`.

- Keep this repository Apache-2.0 licensed.
- Use Helm CLI for chart generation and validation.
- Run `scripts/validate-chart.sh` after chart changes.
- Do not put secrets in values files.
- Keep the bundled/evaluation database image pinned to `timescale/timescaledb:2.28.0-pg18`.
- Keep production examples on external TimescaleDB, external Valkey-compatible cache, and external S3-compatible object storage.
- Treat `charts/opencord/examples/single-node-values.yaml` as evaluation-only when bundled dependencies are enabled.
- Do not move chart source into the server or clients repos.
