terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.170.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
  max_retries = 3
}
