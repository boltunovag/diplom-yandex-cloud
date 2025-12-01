resource "yandex_vpc_network" "diplom-network" {
  name = "diplom-network"
}

resource "yandex_vpc_subnet" "public-subnet-a" {
  name           = "public-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# ИСПРАВЛЕНО: route_table_id добавлен напрямую в существующий ресурс
resource "yandex_vpc_subnet" "private-subnet-a" {
  name           = "private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private-route-table.id  # ← ключевая строка
}

# NAT Gateway для интернета из приватных подсетей
resource "yandex_vpc_gateway" "nat-gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

# Таблица маршрутизации для NAT
resource "yandex_vpc_route_table" "private-route-table" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.diplom-network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gateway.id
  }
}