resource "null_resource" "generate_ssl" {
    count = "${var.generate_ssl}"
    provisioner "local-exec" {
        command = "bash files/ssl/generate-ssl.sh"
    }
}

resource "openstack_compute_keypair_v2" "atx2016" {
    name = "swarm-${var.cluster_name}"
    public_key = "${file(var.public_key_path)}"
}

resource "null_resource" "generate_ssh_keys" {
    provisioner "local-exec" {
        command = "if [ ! -e keys/${var.deis_keyname} ]; then ssh-keygen -f keys/${var.deis_keyname} -P ''; fi"
    }
}

resource "openstack_networking_floatingip_v2" "atx2016_ingress" {
    count = "1"
    pool = "${var.floatingip_pool}"
}

resource "openstack_compute_instance_v2" "atx2016_ingress" {
    name = "${var.cluster_name}-ingress"
    image_name = "${var.image_name}"
    flavor_name = "${var.flavor}"
    key_pair = "${openstack_compute_keypair_v2.atx2016.name}"
    network {
        name = "${openstack_networking_network_v2.atx2016.name}"
    }
    security_groups = [
        "${openstack_compute_secgroup_v2.atx2016_ingress.name}",
        "${openstack_compute_secgroup_v2.atx2016.name}"
    ]
    floating_ip = "${openstack_networking_floatingip_v2.atx2016_ingress.0.address}"
    depends_on = [
        "openstack_networking_network_v2.atx2016",
        "openstack_networking_subnet_v2.atx2016",
        "openstack_networking_router_v2.atx2016",
        "openstack_networking_router_interface_v2.atx2016",
    ]
    provisioner "remote-exec" {
        inline = [
            "sudo modprobe ip_vs",
            "sudo modprobe ip_vs_rr",
            "sudo modprobe ip_vs_sh"
        ]
        connection {
            user = "core"
        }
    }


}

output "ingress" {
    value = "ssh -A ${openstack_networking_floatingip_v2.atx2016_ingress.0.address}"
}
