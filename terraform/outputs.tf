output "network_id" {
  description = "Self-link/id da VPC (consumo pelo infra-k8s)."
  value       = google_compute_network.main.id
}

output "subnet_id" {
  description = "Self-link/id da subnet regional."
  value       = google_compute_subnetwork.main.id
}

output "connection_name" {
  description = "Connection name do Cloud SQL (project:region:instance)."
  value       = google_sql_database_instance.main.connection_name
}

output "db_name" {
  description = "Database da aplicação."
  value       = google_sql_database.app.name
}

output "db_user" {
  description = "Usuário PostgreSQL da aplicação."
  value       = google_sql_user.api.name
}

output "db_password_secret_id" {
  description = "Secret Manager secret_id da senha (sem o valor)."
  value       = google_secret_manager_secret.db_password.secret_id
}
