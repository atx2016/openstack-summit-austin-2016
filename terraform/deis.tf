
resource "openstack_networking_floatingip_v2" "atx2016_deis" {
    pool = "${var.floatingip_pool}"
}

resource "null_resource" "deis_discovery_url" {
    count = "${var.generate_discovery_url}"
    provisioner "local-exec" {
        command = "curl -s 'https://discovery.etcd.io/new?size=${var.deis_cluster_size}' > files/deis_discovery_url"
    }
}

resource "null_resource" "update_cloud_init_deis" {
    provisioner "local-exec" {
        command = "sed -i \"s|^    discovery:.*$|    discovery: $(cat files/deis_discovery_url)|\" files/deis_cloud-init"
    }
    depends_on = [
        "null_resource.deis_discovery_url"
    ]
}

resource "openstack_compute_instance_v2" "atx2016_deis_primary" {
    name = "deis-${var.cluster_name}-0"
    image_name = "${var.deis_image_name}"
    flavor_name = "${var.deis_flavor}"
    key_pair = "${openstack_compute_keypair_v2.atx2016.name}"
    user_data = "${file("files/deis_cloud-init")}"
    network {
        name = "${openstack_networking_network_v2.atx2016.name}"
    }
    security_groups = [
        "${openstack_compute_secgroup_v2.atx2016_deis.name}",
        "${openstack_compute_secgroup_v2.atx2016.name}"
    ]
    floating_ip = "${element(openstack_networking_floatingip_v2.atx2016_deis.*.address, count.index)}"
    depends_on = [
        "openstack_compute_instance_v2.atx2016_swarm"
    ]
}

resource "openstack_compute_instance_v2" "atx2016_deis" {
    name = "deis-${var.cluster_name}-${count.index + 1}"
    count = "${var.deis_cluster_size - 1}"
    image_name = "${var.deis_image_name}"
    flavor_name = "${var.deis_flavor}"
    key_pair = "${openstack_compute_keypair_v2.atx2016.name}"
    user_data = "${file("files/deis_cloud-init")}"
    network {
        name = "${openstack_networking_network_v2.atx2016.name}"
    }
    security_groups = [
        "${openstack_compute_secgroup_v2.atx2016_deis.name}",
        "${openstack_compute_secgroup_v2.atx2016.name}"
    ]
    depends_on = [
        "openstack_compute_instance_v2.atx2016_deis_primary"
    ]
}

resource "null_resource" "prepare_deis" {
    count = "${var.deis_cluster_size}"
    provisioner "file" {
        source = "keys/"
        destination = "/home/core/.ssh/"
        connection {
            user = "core"
            bastion_host = "${openstack_networking_floatingip_v2.atx2016_deis.address}"
            host = "${element(concat(openstack_compute_instance_v2.atx2016_deis.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.atx2016_deis_primary.*.network.0.fixed_ip_v4), count.index )}"
        }
    }
    provisioner "remote-exec" {
        inline = [
            "chown core:core /home/core/.ssh/${var.deis_keyname}*",
            "chmod 0600 /home/core/.ssh/${var.deis_keyname}",
            "cat /home/core/.ssh/${var.deis_keyname}.pub >> /home/core/.ssh/authorized_keys",
            "sudo mkdir -p /opt/bin",
           "if [[ ! -e /opt/bin/deisctl ]]; then curl -sSL http://deis.io/deisctl/install.sh | sudo sh -s ${var.deisctl_version}; fi",
            "export DOMAIN=${var.deis_domain}",
            "if [[ -z $DOMAIN ]]; then export DOMAIN=${openstack_networking_floatingip_v2.atx2016_deis.address}.xip.io; fi",
            "/opt/bin/deisctl config platform set domain=$DOMAIN",
            "/opt/bin/deisctl config platform set sshPrivateKey=/home/core/.ssh/${var.deis_keyname}",
        ]
        connection {
            user = "core"
            bastion_host = "${openstack_networking_floatingip_v2.atx2016_deis.address}"
            host = "${element(concat(openstack_compute_instance_v2.atx2016_deis.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.atx2016_deis_primary.*.network.0.fixed_ip_v4), count.index )}"
        }
    }
    depends_on = [
        "null_resource.update_cloud_init_deis",
        "null_resource.generate_ssh_keys",
        "openstack_compute_instance_v2.atx2016_deis_primary",
        "openstack_compute_instance_v2.atx2016_deis",
    ]
    provisioner "local-exec" {
        command = "cat <<'EOF' >> ssh_config\nHost deis-${count.index}\n    Hostname ${element(concat(openstack_compute_instance_v2.atx2016_deis.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.atx2016_deis_primary.*.network.0.fixed_ip_v4), count.index)}\n\nEOF"
    }
}

resource "null_resource" "install_deis" {
   provisioner "remote-exec" {
        inline = [
            "/opt/bin/deisctl install platform",
            "/opt/bin/deisctl start platform",
        ]
        connection {
            user = "core"
            host = "${openstack_networking_floatingip_v2.atx2016_deis.0.address}"
        }
    }
    depends_on = [
        "null_resource.prepare_deis",
    ]
}

output "DEIS" {
    value = "\nRun the following to register your first [admin] user: $ deis register http://deis.${openstack_networking_floatingip_v2.atx2016_deis.address}.xip.io"
}

