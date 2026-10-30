variable "project_id" {
  type        = string
  description = "GCP project ID da demo."
  default     = "vcosta-fiap-tech-challenge"
}

variable "region" {
  type        = string
  description = "Região primária."
  default     = "us-central1"
}

variable "db_instance_name" {
  type        = string
  description = "Nome da instância Cloud SQL."
  default     = "tech-challenge-pg"
}

variable "db_tier" {
  type        = string
  description = "Tier da instância Cloud SQL."
  default     = "db-g1-small"
}
