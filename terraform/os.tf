resource "openstack_blockstorage_volume_v1" "os_master_volume" {
  region = ""
  name = "os-master-volume"
  description = "Volume to persist Jenkins master configuration"
  size = "${var.os_master_volume_size}"
  
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
}