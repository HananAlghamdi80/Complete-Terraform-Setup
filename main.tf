provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

resource "alicloud_vpc" "my_vpc" {
  vpc_name   = "my-vpc"
  cidr_block = "10.0.0.0/16"
}

resource "alicloud_vswitch" "public_subnet" {
  vswitch_name = "public-subnet"
  cidr_block   = "10.0.1.0/24"
  vpc_id       = alicloud_vpc.my_vpc.id
  zone_id      = "me-central-1a"
}

resource "alicloud_vswitch" "private_subnet" {
  vswitch_name = "private-subnet"
  cidr_block   = "10.0.2.0/24"
  vpc_id       = alicloud_vpc.my_vpc.id
  zone_id      = "me-central-1a"
}

resource "alicloud_security_group" "public_sg" {
  name   = "han_Securitypublicgroup"
  vpc_id = alicloud_vpc.my_vpc.id
}

resource "alicloud_security_group" "private_sg" {
  name   = "han_SecurityPrivateGroup"
  vpc_id = alicloud_vpc.my_vpc.id
}

resource "alicloud_security_group_rule" "allow_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.public_sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_ssh_public" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.public_sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_ssh_private" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.private_sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_nat_gateway" "nat_gateway" {
  vpc_id           = alicloud_vpc.my_vpc.id
  nat_gateway_name = "enhanced-nat-gateway"
  payment_type     = "PayAsYouGo"
  vswitch_id       = alicloud_vswitch.public_subnet.id
  nat_type         = "Enhanced"
}

resource "alicloud_eip" "nat_eip" {
  bandwidth           = 5
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_eip_association" "nat_eip_association" {
  allocation_id = alicloud_eip.nat_eip.id
  instance_id   = alicloud_nat_gateway.nat_gateway.id
}

resource "alicloud_snat_entry" "default" {
  snat_table_id     = alicloud_nat_gateway.nat_gateway.snat_table_ids
  source_vswitch_id = alicloud_vswitch.private_subnet.id
  snat_ip           = alicloud_eip.nat_eip.ip_address
}

resource "alicloud_instance" "public_instance" {
  instance_name   = "bastion-host"
  instance_type   = "ecs.g6.large"
  image_id        = "ubuntu_20_04_x64_20G_alibase_20240819.vhd"
  vswitch_id      = alicloud_vswitch.public_subnet.id
  security_groups = [alicloud_security_group.public_sg.id]
  internet_charge_type = "PayByTraffic"
  internet_max_bandwidth_out = 5
  instance_charge_type = "PostPaid"
  key_name = "han2"
  system_disk_category = "cloud_essd"
  system_disk_size     = 40
}

resource "alicloud_instance" "private_instance" {
  instance_name   = "private-instance"
  instance_type   = "ecs.g6.large"
  image_id        = "ubuntu_20_04_x64_20G_alibase_20240819.vhd"
  vswitch_id      = alicloud_vswitch.private_subnet.id
  security_groups = [alicloud_security_group.private_sg.id]
  instance_charge_type = "PostPaid"
  key_name = "han2"
  system_disk_category = "cloud_essd"
  system_disk_size     = 40
}
