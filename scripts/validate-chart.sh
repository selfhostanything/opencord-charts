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

def container_for(docs, deployment_name, container_name)
  resource(docs, "Deployment", deployment_name)
    &.dig("spec", "template", "spec", "containers")
    .to_a
    .find { |container| container["name"] == container_name }
end

def env_var(container, name)
  container.fetch("env", []).find { |entry| entry["name"] == name }
end

def ingress_path_backend_services(ingress)
  ingress
    .dig("spec", "rules")
    .to_a
    .flat_map { |rule| rule.dig("http", "paths").to_a }
    .map { |path| [path["path"], path.dig("backend", "service", "name")] }
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

config = resource(default, "ConfigMap", "opencord-config")

%w[
  OPENCORD_API_ADDR
  OPENCORD_REALTIME_ADDR
  OPENCORD_WORKER_ADDR
  KAFKA_BOOTSTRAP_SERVERS
  SCYLLA_CONTACT_POINTS
  SCYLLA_KEYSPACE
  OPENCORD_LIVEKIT_URL
  OPENCORD_MEDIA_REGION
  OPENCORD_MEDIA_TOKEN_TTL_SECONDS
  OPENCORD_OTEL_ENABLED
  OPENCORD_OTEL_ENDPOINT
  OPENCORD_OTEL_SERVICE_NAME
  OPENCORD_LOG_FORMAT
  OPENCORD_LOG_FILTER
  OPENCORD_METRICS_PROMETHEUS_ENABLED
].each do |key|
  assert("default ConfigMap must render #{key}") do
    config&.dig("data", key).is_a?(String)
  end
end

assert("default ConfigMap must render Kafka bootstrap servers") do
  config&.dig("data", "KAFKA_BOOTSTRAP_SERVERS") == "kafka:9092"
end

assert("default ConfigMap must render Scylla contact points") do
  config&.dig("data", "SCYLLA_CONTACT_POINTS") == "scylladb:9042"
end

assert("default ConfigMap must bind worker on port 8082") do
  config&.dig("data", "OPENCORD_WORKER_ADDR") == "0.0.0.0:8082"
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

%w[opencord-api opencord-realtime opencord-worker].each do |deployment_name|
  assert("#{deployment_name} must render read-only root filesystems") do
    containers = resource(default, "Deployment", deployment_name)
      &.dig("spec", "template", "spec", "containers")

    containers.is_a?(Array) && !containers.empty? && containers.all? do |container|
      container.dig("securityContext", "readOnlyRootFilesystem") == true
    end
  end
end

assert("realtime deployment must receive DATABASE_URL") do
  realtime = container_for(default, "opencord-realtime", "realtime")
  database_env = env_var(realtime || {}, "DATABASE_URL")

  database_env&.dig("valueFrom", "secretKeyRef", "key") == "DATABASE_URL"
end

assert("worker deployment must expose its health port") do
  worker = container_for(default, "opencord-worker", "worker")

  worker&.fetch("ports", []).to_a.any? do |port|
    port["name"] == "http" && port["containerPort"] == 8082
  end
end

assert("worker deployment must probe /healthz") do
  worker = container_for(default, "opencord-worker", "worker")

  worker&.dig("readinessProbe", "httpGet", "path") == "/healthz" &&
    worker&.dig("livenessProbe", "httpGet", "path") == "/healthz"
end

assert("production chart must render LiveKit backend env names") do
  api = container_for(production, "opencord-api", "api")
  livekit_key = env_var(api || {}, "OPENCORD_LIVEKIT_API_KEY")
  livekit_secret = env_var(api || {}, "OPENCORD_LIVEKIT_API_SECRET")

  livekit_key&.dig("valueFrom", "secretKeyRef", "key") == "OPENCORD_LIVEKIT_API_KEY" &&
    livekit_secret&.dig("valueFrom", "secretKeyRef", "key") == "OPENCORD_LIVEKIT_API_SECRET"
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

assert("production ingress must route API and realtime services") do
  path_services = ingress_path_backend_services(resource(production, "Ingress", "opencord"))

  path_services.include?(["/", "opencord-api"]) &&
    path_services.include?(["/gateway", "opencord-realtime"])
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
