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

resource "template_file" "ssh_config" {
    template = "templates/ssh_config"
    vars {
        swarm_ip = "${openstack_networking_floatingip_v2.atx2016_swarm.0.address}"
        deis_ip = "${openstack_networking_floatingip_v2.atx2016_deis.0.address}"
    }
    depends_on = [
        "openstack_networking_floatingip_v2.atx2016_swarm",
        "openstack_networking_floatingip_v2.atx2016_deis"
    ]
}

resource "null_resource" "write_ssh_config" {
    count = "${var.generate_discovery_url}"
    provisioner "local-exec" {
        command = "cat <<'EOF' > ssh_config\n${template_file.ssh_config.rendered}\nEOF"
    }
    depends_on = ["template_file.ssh_config"]
}
