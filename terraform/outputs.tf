output "instance_name" {
  description = "Nome da instância Cloud SQL."
  value       = google_sql_database_instance.main.name
}

output "connection_name" {
  description = "Connection name do Cloud SQL (project:region:instance)."
  value       = google_sql_database_instance.main.connection_name
}
