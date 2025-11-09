output "monitoring_namespace" {
  description = "Name of the monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_release_name" {
  description = "Name of the Prometheus Helm release"
  value       = helm_release.prometheus.name
}

output "metrics_server_release_name" {
  description = "Name of the Metrics Server Helm release"
  value       = helm_release.metrics_server.name
}# Updated 20251109_123805
