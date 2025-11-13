variable "cloud_id" {
  description = "Yandex cloud ID"
  type        = string
  sensitive   = true
}

variable "folder_id" {
  description = "Yandex cloud folder ID"
  type        = string
  sensitive   = true
}

variable "service_account_key_file" {
  description = "Path to service account key file"
  type        = string
  default     = "key.json"
}
