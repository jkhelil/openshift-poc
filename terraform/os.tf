
resource "openstack_compute_keypair_v2" "admin" {
  name = "my-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA1PKqbX2qQMYwGkY/s+H+s3cbXl2o1w/LmZH7M76V/SeVjY74i7+du8jVzCADz5Tc2kGHsPOrt0pWqbbI+hxO9lIn6YClBgoLz0oVkz2Wj7MqPterrZdT9sM9Z0R43wdKSbu0ZReWKrGFfzPFspTXMZh2Xif2lrPpMd0q4JkxX12Lz6HBxCSDJNAp+maInuyDhFZiJ8JCP4SZ4z7h1zg10dEGDuBorlvrxJVdHQ5/Z7jacXbI7MWzi7By3x+2GNLfJ7xv/dWIN/KR3D7n9wzJHBxnt+O948BF5Lpri7oAOcntYzlZDcGlpLDhOoIu8y8cVLSfl1mPuOb3tQkUfnKelw== adminapptest@jumphost"
}

resource "openstack_compute_floatingip_v2" "os_minion_floatip" {
  count = "3"
  region = ""
  pool = "${var.network_poolname}"
}

resource "openstack_blockstorage_volume_v1" "os_minion_volume" {
  count = "3"
  region = ""
  name = "os-minion-volume"
  description = "Volume to persist  master configuration"
  size = "${var.os_master_volume_size}"
  
}

resource "openstack_blockstorage_volume_v1" "os_master_volume" {
  region = ""
  name = "os-master-volume"
  description = "Volume to persist  master configuration"
  size = "${var.os_master_volume_size}"
  
}

resource "openstack_networking_network_v2" "os_network_internal" {
    name = "private"
    admin_state_up = "true"
    shared = "false"
}


resource "openstack_compute_floatingip_v2" "os_master_floatip" {
  count = "1"
  region = ""
  pool = "${var.network_poolname}"
}

resource "openstack_compute_instance_v2" "os-master" {
  count = "1"
  name = "os-master.example.com"
  image_name = "${var.image_name}"
  flavor_name = "m1.medium"
  key_pair = "${openstack_compute_keypair_v2.admin.name}"
  metadata {
    type = "os-master"
  }
  floating_ip = "${element(openstack_compute_floatingip_v2.os_master_floatip.*.address, count.index)}"  
  volume {
	volume_id = "${openstack_blockstorage_volume_v1.os_master_volume.id}"
	device = "/dev/vdb"
  }
  network {
    uuid = "e08085a7-c46a-4e34-9e7d-ae0d7697d58f"
  }
}

resource "openstack_compute_instance_v2" "os-minion" {
  count = "3"
  name = "${format("os-minion-%02d.example.com", count.index + 1)}"
  image_name = "${var.image_name}"
  flavor_name = "m1.medium"
  key_pair = "${openstack_compute_keypair_v2.admin.name}"
  metadata {
    type = "${format("os-minion-%02d", count.index + 1)}"
  }
  floating_ip = "${element(openstack_compute_floatingip_v2.os_minion_floatip.*.address, count.index)}"  
  volume {
	volume_id = "${element(openstack_blockstorage_volume_v1.os_minion_volume.*.id,count.index)}"
	device = "/dev/vdb"
  }
  network {
    uuid = "e08085a7-c46a-4e34-9e7d-ae0d7697d58f"
  }
}