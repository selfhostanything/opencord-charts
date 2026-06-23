# AGENTS.md

Rules for agents working in `opencord-charts`.

- Keep this repository Apache-2.0 licensed.
- Use Helm CLI for chart generation and validation.
- Run `scripts/validate-chart.sh` after chart changes.
- Prefer larger coherent checkpoints over tiny commits. Keep chart edits and
  validation iterations local, batch related chart/docs behavior, run local
  validation first, then commit and push once for the batch.
- Do not use CI as the inner development loop. Push after Helm/schema/template
  validation has already passed or after documenting a real local blocker.
- Do not put secrets in values files.
- Keep the bundled/evaluation database image pinned to `timescale/timescaledb:2.28.1-pg18-oss`.
- Use readable version-number pins for images, charts, CI actions, and
  dependencies. Do not pin them by image digest, commit SHA, or other hash-style
  references unless a human explicitly approves a narrow exception.
- Do not use Docker `latest` tags. Prefer major.minor tags that float patch
  updates where the image publishes them; use explicit release/date tags for
  images that do not publish stable major.minor tags.
- Keep production examples on external TimescaleDB, external Valkey-compatible cache, and external S3-compatible object storage.
- Treat `charts/opencord/examples/single-node-values.yaml` as evaluation-only when bundled dependencies are enabled.
- Do not move chart source into the server or clients repos.
