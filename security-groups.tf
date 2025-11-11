# security-groups.tf

# Security Group для Bastion host
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "Security group for Bastion host"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]  # SSH доступ отовсюду
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для балансировщика
resource "yandex_vpc_security_group" "loadbalancer-sg" {
  name        = "loadbalancer-sg"
  description = "Security group for Load Balancer"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]  # HTTP доступ отовсюду
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для внутренних серверов (Web, Elasticsearch)
resource "yandex_vpc_security_group" "internal-sg" {
  name        = "internal-sg"
  description = "Security group for internal servers"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["192.168.10.0/24"]  # SSH из подсети бастиона
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    security_group_id = yandex_vpc_security_group.loadbalancer-sg.id  # HTTP от балансера
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["192.168.0.0/16"]  # Для Health Check балансировщика
  }

  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["192.168.0.0/16"]  # Elasticsearch из внутренней сети
  }

  ingress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["192.168.0.0/16"]  # Zabbix Agent из внутренней сети
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для мониторинга и логов (Zabbix, Kibana)
resource "yandex_vpc_security_group" "monitoring-sg" {
  name        = "monitoring-sg"
  description = "Security group for monitoring services"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]  # SSH доступ отовсюду
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]  # Web UI доступ отовсюду
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]  # HTTPS доступ
  }

  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]  # Kibana
  }

  ingress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["192.168.0.0/16"]  # Zabbix Trapper из внутренней сети
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
