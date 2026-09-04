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

variable "network_name" {
  type        = string
  description = "Nome da VPC dedicada."
  default     = "techchallenge-vpc"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR da subnet regional."
  default     = "10.10.0.0/24"
}

variable "db_instance_name" {
  type        = string
  description = "Nome da instância Cloud SQL."
  default     = "techchallenge-pg"
}

variable "db_name" {
  type        = string
  description = "Nome do database da aplicação."
  default     = "techchallenge"
}

variable "db_user" {
  type        = string
  description = "Usuário PostgreSQL da aplicação."
  default     = "api"
}

variable "db_tier" {
  type        = string
  description = "Tier da instância Cloud SQL."
  default     = "db-f1-micro"
}
