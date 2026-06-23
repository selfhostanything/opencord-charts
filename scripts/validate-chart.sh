#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_DIR="${ROOT_DIR}/charts/opencord"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

helm lint "${CHART_DIR}"

helm template opencord "${CHART_DIR}" > "${TMP_DIR}/default.yaml"
helm template opencord "${CHART_DIR}" \
  -f "${CHART_DIR}/examples/production-values.yaml" \
  > "${TMP_DIR}/production.yaml"
helm template opencord "${CHART_DIR}" \
  -f "${CHART_DIR}/examples/single-node-values.yaml" \
  > "${TMP_DIR}/single-node.yaml"
helm template opencord "${CHART_DIR}" \
  -f "${CHART_DIR}/examples/vultr-values.yaml" \
  > "${TMP_DIR}/vultr.yaml"
helm template opencord "${CHART_DIR}" \
  --set ingress.enabled=true \
  --set customDomains.enabled=true \
  --set customDomains.hosts[0]=customer.example.com \
  --set customDomains.tlsSecretName=opencord-custom-domains-tls \
  > "${TMP_DIR}/custom-domains.yaml"

ruby - "${TMP_DIR}" <<'RUBY'
require "yaml"

tmp_dir = ARGV.fetch(0)

def load_docs(path)
  YAML.load_stream(File.read(path)).compact
end

def names(docs, kind)
  docs.select { |doc| doc["kind"] == kind }.map { |doc| doc.dig("metadata", "name") }
end

def resource(docs, kind, name)
  docs.find { |doc| doc["kind"] == kind && doc.dig("metadata", "name") == name }
end

def assert(message)
  raise message unless yield
end

default = load_docs(File.join(tmp_dir, "default.yaml"))
production = load_docs(File.join(tmp_dir, "production.yaml"))
single_node = load_docs(File.join(tmp_dir, "single-node.yaml"))
vultr = load_docs(File.join(tmp_dir, "vultr.yaml"))
custom_domains = load_docs(File.join(tmp_dir, "custom-domains.yaml"))

%w[api realtime worker].each do |component|
  assert("default chart must render #{component} Deployment") do
    names(default, "Deployment").include?("opencord-#{component}")
  end
  assert("production chart must render #{component} HorizontalPodAutoscaler") do
    names(production, "HorizontalPodAutoscaler").include?("opencord-#{component}")
  end
end

assert("production chart must render an Ingress") do
  names(production, "Ingress").include?("opencord")
end

assert("default chart must expose explicit CORS allowed-origin config") do
  resource(default, "ConfigMap", "opencord-config")
    &.dig("data", "OPENCORD_ALLOWED_ORIGINS") == ""
end

assert("single-node chart must render bundled TimescaleDB StatefulSet") do
  names(single_node, "StatefulSet").include?("opencord-timescaledb")
end

assert("single-node chart must render bundled Valkey StatefulSet") do
  names(single_node, "StatefulSet").include?("opencord-valkey")
end

assert("single-node chart must pin TimescaleDB image to 2.28.1-pg18-oss") do
  single_node.any? do |doc|
    doc["kind"] == "StatefulSet" &&
      doc.dig("metadata", "name") == "opencord-timescaledb" &&
      doc.dig("spec", "template", "spec", "containers").to_a.any? do |container|
        container["image"] == "timescale/timescaledb:2.28.1-pg18-oss"
      end
  end
end

assert("vultr chart must keep database external for self-hosted TimescaleDB") do
  names(vultr, "StatefulSet").none? { |name| name == "opencord-timescaledb" }
end

assert("vultr chart must render TLS ingress") do
  vultr.any? do |doc|
    doc["kind"] == "Ingress" &&
      doc.dig("metadata", "name") == "opencord" &&
      doc.dig("spec", "tls").to_a.any?
  end
end

assert("custom-domain chart values must render extra ingress host") do
  custom_domains.any? do |doc|
    doc["kind"] == "Ingress" &&
      doc.dig("spec", "rules").to_a.any? { |rule| rule["host"] == "customer.example.com" }
  end
end

assert("custom-domain chart values must render custom TLS secret") do
  custom_domains.any? do |doc|
    doc["kind"] == "Ingress" &&
      doc.dig("spec", "tls").to_a.any? { |tls| tls["secretName"] == "opencord-custom-domains-tls" }
  end
end
RUBY
