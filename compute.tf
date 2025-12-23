# compute.tf - ПОЛНЫЙ ИСПРАВЛЕННЫЙ ФАЙЛ

# Bastion
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8498pb5smsd5ch4gid"
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
  }

  metadata = {
    ssh-keys  = "ubuntu:${file("~/.ssh/yc-ed25519.pub")}"
    user-data = "${file("bastion-user-data.yaml")}"
  }

  scheduling_policy {
    preemptible = false
  }
}

# Web Server 1
resource "yandex_compute_instance" "web-1" {
  name        = "web-1"
  hostname    = "web-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8498pb5smsd5ch4gid"
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal-sg.id]
  }

  metadata = {
    ssh-keys  = "ubuntu:${file("~/.ssh/yc-ed25519.pub")}"
    user-data = "${file("bastion-user-data.yaml")}"
  }

  scheduling_policy {
    preemptible = false
  }
}

# Web Server 2
resource "yandex_compute_instance" "web-2" {
  name        = "web-2"
  hostname    = "web-2"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8498pb5smsd5ch4gid"
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal-sg.id]
  }

  metadata = {
    ssh-keys  = "ubuntu:${file("~/.ssh/yc-ed25519.pub")}"
    user-data = "${file("bastion-user-data.yaml")}"
  }

  scheduling_policy {
    preemptible = false
  }
}

# Zabbix Server
resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8498pb5smsd5ch4gid"
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.monitoring-sg.id]
  }

  metadata = {
    ssh-keys  = "ubuntu:${file("~/.ssh/yc-ed25519.pub")}"
    user-data = "${file("bastion-user-data.yaml")}"
  }

  scheduling_policy {
    preemptible = false
  }
}

# Elasticsearch Server
resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname    = "elasticsearch"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8498pb5smsd5ch4gid"
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal-sg.id]
  }

  metadata = {
    ssh-keys  = "ubuntu:${file("~/.ssh/yc-ed25519.pub")}"
    user-data = "${file("bastion-user-data.yaml")}"
  }

  scheduling_policy {
    preemptible = false
  }
}

# Kibana Server
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8498pb5smsd5ch4gid"
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.monitoring-sg.id]
  }

  metadata = {
    ssh-keys  = "ubuntu:${file("~/.ssh/yc-ed25519.pub")}"
    user-data = "${file("bastion-user-data.yaml")}"
  }

  scheduling_policy {
    preemptible = false
  }
}