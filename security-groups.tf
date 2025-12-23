# Генератор уникального суффикса
resource "random_id" "suffix" {
  byte_length = 2
  prefix      = "diplom-"
}

# Security Group для Bastion host
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion-sg-${random_id.suffix.hex}"
  description = "Security group for Bastion host"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для балансировщика
resource "yandex_vpc_security_group" "loadbalancer-sg" {
  name        = "loadbalancer-sg-${random_id.suffix.hex}"
  description = "Security group for Load Balancer"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для внутренних серверов (web-1, web-2, elasticsearch)
resource "yandex_vpc_security_group" "internal-sg" {
  name        = "internal-sg-${random_id.suffix.hex}"
  description = "Security group for internal servers"
  network_id  = yandex_vpc_network.diplom-network.id

  # SSH только из публичной подсети (bastion)
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["192.168.10.0/24"]
  }

  # HTTP от балансировщика
  ingress {
    protocol          = "TCP"
    port              = 80
    security_group_id = yandex_vpc_security_group.loadbalancer-sg.id
  }

  # HTTP для диагностики между хостами
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24"]
  }

  # Elasticsearch: доступ для Kibana (из публичной подсети)
  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["192.168.10.0/24"]
  }

  # Elasticsearch: доступ для Filebeat (из приватной подсети)
  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["192.168.20.0/24"]
  }

  # Zabbix Agent: принимает проверки от Zabbix Server
  ingress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["192.168.10.0/24"]  # ← Подсеть Zabbix Server
  }

  # Zabbix Server: для исходящих соединений агента
  egress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["192.168.10.0/24"]  # ← Подсеть Zabbix Server
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для мониторинга (zabbix, kibana)
resource "yandex_vpc_security_group" "monitoring-sg" {
  name        = "monitoring-sg-${random_id.suffix.hex}"
  description = "Security group for monitoring services"
  network_id  = yandex_vpc_network.diplom-network.id

  # SSH извне
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (Zabbix UI, Kibana)
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Kibana
  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Zabbix Server: принимает соединения от агентов
  ingress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["192.168.20.0/24"]  # ← Подсеть агентов
  }

  # Zabbix Agent: для проверки агентов
  egress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["192.168.20.0/24"]  # ← Подсеть агентов
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}