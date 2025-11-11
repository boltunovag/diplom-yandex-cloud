resource "yandex_vpc_network" "diplom-network" {
  name = "diplom-network"
}

resource "yandex_vpc_subnet" "public-subnet-a" {
  name           = "public-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# UPDATED: Add the 'route_table_id' argument to your existing private subnet
resource "yandex_vpc_subnet" "private-subnet-a" {
  name           = "private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private-route-table.id # <- Add this line
}

# NAT Gateway for internet access from private subnets
resource "yandex_vpc_gateway" "nat-gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

# Route table to direct traffic through the NAT Gateway
resource "yandex_vpc_route_table" "private-route-table" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.diplom-network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gateway.id
  }
}

# 
# resource "yandex_vpc_route_table_association" "private-a-binding" {
#   subnet_id      = yandex_vpc_subnet.private-subnet-a.id
#   route_table_id = yandex_vpc_route_table.private-route-table.id
# }
