# AGENTS.md

Rules for agents working in `opencord-charts`.

- Keep this repository Apache-2.0 licensed.
- Use Helm CLI for chart generation and validation.
- Run `helm lint charts/opencord` and `helm template opencord charts/opencord` after chart changes.
- Do not put secrets in values files.
- Keep the bundled/evaluation database image pinned to `timescale/timescaledb:2.28.0-pg18`.
- Do not move chart source into the server or clients repos.
