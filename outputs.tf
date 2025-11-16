# outputs.tf

# Внешний IP Bastion для подключения
output "bastion_external_ip" {
  description = "External IP address of Bastion host"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

# Внутренние IP веб-серверов
output "web_1_internal_ip" {
  description = "Internal IP address of web-1"
  value       = yandex_compute_instance.web-1.network_interface.0.ip_address
}

output "web_2_internal_ip" {
  description = "Internal IP address of web-2"
  value       = yandex_compute_instance.web-2.network_interface.0.ip_address
}

# ID созданных Security Groups
output "security_group_ids" {
  description = "IDs of created security groups"
  value = {
    bastion      = yandex_vpc_security_group.bastion-sg.id
    internal     = yandex_vpc_security_group.internal-sg.id
    loadbalancer = yandex_vpc_security_group.loadbalancer-sg.id
    monitoring   = yandex_vpc_security_group.monitoring-sg.id
  }
}

output "load_balancer_ip" {
  value = yandex_alb_load_balancer.web-balancer.listener.0.endpoint.0.address.0.external_ipv4_address.0.address
}

# Внешний IP Zabbix для доступа к веб-интерфейсу
output "zabbix_external_ip" {
  description = "External IP address of Zabbix server"
  value       = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

# Внутренний IP Zabbix для агентов
output "zabbix_internal_ip" {
  description = "Internal IP address of Zabbix server for agents"
  value       = yandex_compute_instance.zabbix.network_interface.0.ip_address
}

# Elasticsearch internal IP
output "elasticsearch_internal_ip" {
  description = "Internal IP address of Elasticsearch server"
  value       = yandex_compute_instance.elasticsearch.network_interface.0.ip_address
}

# Kibana external IP
output "kibana_external_ip" {
  description = "External IP address of Kibana server"
  value       = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}
