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

# Security Group для внутренних серверов
resource "yandex_vpc_security_group" "internal-sg" {
  name        = "internal-sg-${random_id.suffix.hex}"
  description = "Security group for internal servers"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["192.168.10.0/24"]
  }

  ingress {
    protocol          = "TCP"
    port              = 80
    security_group_id = yandex_vpc_security_group.loadbalancer-sg.id
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["192.168.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["192.168.10.0/24"]
  }

  ingress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["192.168.10.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для мониторинга
resource "yandex_vpc_security_group" "monitoring-sg" {
  name        = "monitoring-sg-${random_id.suffix.hex}"
  description = "Security group for monitoring services"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["192.168.20.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}