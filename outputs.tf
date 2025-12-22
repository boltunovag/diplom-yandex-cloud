# outputs.tf
output "bastion_external_ip" {
  description = "External IP of Bastion host"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "load_balancer_ip" {
  description = "External IP of Load Balancer"
  value       = yandex_alb_load_balancer.web-balancer.listener.0.endpoint.0.address.0.external_ipv4_address.0.address
}

output "web_servers_ips" {
  description = "Internal IPs of web servers"
  value = {
    web1 = yandex_compute_instance.web-1.network_interface.0.ip_address
    web2 = yandex_compute_instance.web-2.network_interface.0.ip_address
  }
}

output "elasticsearch_internal_ip" {
  description = "Internal IP of Elasticsearch server"
  value       = yandex_compute_instance.elasticsearch.network_interface.0.ip_address
}

output "kibana_external_ip" {
  description = "External IP of Kibana server"
  value       = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}