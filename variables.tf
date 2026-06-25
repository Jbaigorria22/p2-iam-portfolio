variable "aws_region" {
  description = "Region principal del proyecto"
  type        = string
  default     = "sa-east-1"
}

variable "aws_profile" {
  description = "Perfil CLI de AWS a usar"
  type        = string
  default     = "joaquin-admin"
}

variable "account_id" {
  description = "ID de la cuenta AWS"
  type        = string
}

variable "admin_group_name" {
  description = "Nombre del grupo de administradores"
  type        = string
  default     = "Admins"
}

variable "sso_instance_arn" {
  description = "ARN de la instancia de IAM Identity Center"
  type        = string
}

variable "identity_store_id" {
  description = "ID del Identity Store de IAM Identity Center"
  type        = string
}
