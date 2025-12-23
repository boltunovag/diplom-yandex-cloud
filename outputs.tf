# outputs.tf
output "bastion_external_ip" {
  description = "External IP address of Bastion host (changes on recreate)"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "zabbix_external_ip" {
  description = "External IP address of Zabbix server (changes on recreate)"
  value       = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

output "kibana_external_ip" {
  description = "External IP address of Kibana server (changes on recreate)"
  value       = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

output "load_balancer_ip" {
  description = "External IP address of Load Balancer"
  value       = yandex_alb_load_balancer.web-balancer.listener.0.endpoint.0.address.0.external_ipv4_address.0.address
}

# Внутренние IP (стабильные)
output "zabbix_internal_ip" {
  description = "Internal IP address of Zabbix server"
  value       = yandex_compute_instance.zabbix.network_interface.0.ip_address
}

output "web_1_internal_ip" {
  description = "Internal IP address of web-1"
  value       = yandex_compute_instance.web-1.network_interface.0.ip_address
}

output "web_2_internal_ip" {
  description = "Internal IP address of web-2"
  value       = yandex_compute_instance.web-2.network_interface.0.ip_address
}

output "elasticsearch_internal_ip" {
  description = "Internal IP address of Elasticsearch server"
  value       = yandex_compute_instance.elasticsearch.network_interface.0.ip_address
}