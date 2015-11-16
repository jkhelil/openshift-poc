
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
  name = "os-master"
  image_name = "centos-6.6_x86_64-cnftools_delivery"
  flavor_name = "m1.medium"
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
  name = "${format("os-minion-%02d", count.index + 1)}"
  image_name = "centos-6.6_x86_64-cnftools_delivery"
  flavor_name = "m1.medium"
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