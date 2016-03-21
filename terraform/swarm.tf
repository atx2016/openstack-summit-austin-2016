resource "null_resource" "swarm_discovery_url_template" {
    count = "${var.generate_discovery_url}"
    provisioner "local-exec" {
        command = "curl -s 'https://discovery.etcd.io/new' > templates/swarm_discovery_url"
    }
}

resource "template_file" "swarm_discovery_url" {
    template = "templates/swarm_discovery_url"
    depends_on = [
        "null_resource.swarm_discovery_url_template"
    ]
}

resource "template_file" "swarm_cloud_init" {
    template = "templates/swarm_cloud-init"
    vars {
        cluster_token = "${var.cluster_name}"
        discovery_url = "${template_file.swarm_discovery_url.rendered}"
        swarm_version = "${var.swarm_version}"
    }
}

resource "openstack_networking_floatingip_v2" "atx2016_swarm" {
    pool = "${var.floatingip_pool}"
}

resource "openstack_compute_instance_v2" "atx2016_swarm_primary" {
    name = "swarm-${var.cluster_name}-0"
    image_name = "${var.image_name}"
    flavor_name = "${var.flavor}"
    key_pair = "${openstack_compute_keypair_v2.atx2016.name}"
    network {
        name = "${openstack_networking_network_v2.atx2016.name}"
    }
    security_groups = [
        "${openstack_compute_secgroup_v2.atx2016_swarm.name}",
        "${openstack_compute_secgroup_v2.atx2016.name}"
    ]
    floating_ip = "${openstack_networking_floatingip_v2.atx2016_swarm.address}"
    user_data = "${template_file.swarm_cloud_init.rendered}"
    depends_on = [
        "template_file.swarm_cloud_init",
        "null_resource.write_ssh_config",
        "openstack_networking_router_interface_v2.atx2016"
    ]
}

resource "openstack_compute_instance_v2" "atx2016_swarm" {
    name = "swarm-${var.cluster_name}-${count.index + 1}"
    count = "${var.cluster_size - 1}"
    image_name = "${var.image_name}"
    flavor_name = "${var.flavor}"
    key_pair = "${openstack_compute_keypair_v2.atx2016.name}"
    network {
        name = "${openstack_networking_network_v2.atx2016.name}"
    }
    security_groups = [
        "${openstack_compute_secgroup_v2.atx2016_swarm.name}",
        "${openstack_compute_secgroup_v2.atx2016.name}"
    ]
    user_data = "${template_file.swarm_cloud_init.rendered}"
    depends_on = [
        "template_file.swarm_cloud_init",
        "null_resource.write_ssh_config"
    ]
}

resource "null_resource" "install_swarm" {
    count = "${var.cluster_size}"
    provisioner "file" {
        source = "files"
        destination = "/tmp/files"
        connection {
            user = "core"
            host = "${element(concat(openstack_compute_instance_v2.atx2016_swarm.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.atx2016_swarm_primary.*.network.0.fixed_ip_v4), count.index )}"
            bastion_host = "${openstack_networking_floatingip_v2.atx2016_swarm.address}"
        }
    }
    provisioner "remote-exec" {
        inline = [
            # Create TLS certs
            "echo '==> TLS Certificates'",
            "mkdir -p /home/core/.docker",
            "cp /tmp/files/ssl/ca.pem /home/core/.docker/",
            "cp /tmp/files/ssl/cert.pem /home/core/.docker/",
            "cp /tmp/files/ssl/key.pem /home/core/.docker/",
            "echo 'subjectAltName = @alt_names' >> /tmp/files/ssl/openssl.cnf",
            "echo '[alt_names]' >> /tmp/files/ssl/openssl.cnf",
            "echo 'IP.1 = ${element(concat(openstack_compute_instance_v2.atx2016_swarm.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.atx2016_swarm_primary.*.network.0.fixed_ip_v4), count.index)}' >> /tmp/files/ssl/openssl.cnf",
            "echo 'IP.2 = ${openstack_networking_floatingip_v2.atx2016_swarm.address}' >> /tmp/files/ssl/openssl.cnf",
            "echo 'DNS.1 = ${var.fqdn}' >> /tmp/files/ssl/openssl.cnf",
            "echo 'DNS.2 = ${openstack_networking_floatingip_v2.atx2016_swarm.address}.xip.io' >> /tmp/files/ssl/openssl.cnf",
            "openssl req -new -key /tmp/files/ssl/key.pem -out /tmp/files/ssl/cert.csr -subj '/CN=docker-client' -config /tmp/files/ssl/openssl.cnf",
            "openssl x509 -req -in /tmp/files/ssl/cert.csr -CA /tmp/files/ssl/ca.pem -CAkey /tmp/files/ssl/ca-key.pem \\",
            "-CAcreateserial -out /tmp/files/ssl/cert.pem -days 365 -extensions v3_req -extfile /tmp/files/ssl/openssl.cnf",
            "sudo mkdir -p /etc/docker/ssl",
            "sudo cp /tmp/files/ssl/ca.pem /etc/docker/ssl/",
            "sudo cp /tmp/files/ssl/cert.pem /etc/docker/ssl/",
            "sudo cp /tmp/files/ssl/key.pem /etc/docker/ssl/",
            "echo '==> Services'",
            "echo '----> starting registrator'",
            "sudo systemctl start registrator.service",
            "echo '----> starting swarm-agent'",
            "sudo systemctl start swarm-agent.service",
            "echo '----> starting swarm-manager'",
            "sudo systemctl start swarm-manager.service",
        ]
        connection {
            user = "core"
            host = "${element(concat(openstack_compute_instance_v2.atx2016_swarm.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.atx2016_swarm_primary.*.network.0.fixed_ip_v4), count.index )}"
            bastion_host = "${openstack_networking_floatingip_v2.atx2016_swarm.address}"
        }
    }
    provisioner "local-exec" {
        command = "cat <<'EOF' >> ssh_config\nHost swarm-${count.index}\n    Hostname ${element(concat(openstack_compute_instance_v2.atx2016_swarm.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.atx2016_swarm_primary.*.network.0.fixed_ip_v4), count.index)}\n\nEOF"
    }
    depends_on = [
        "openstack_compute_instance_v2.atx2016_swarm_primary",
        "openstack_compute_instance_v2.atx2016_swarm"
    ]
}

output "swarm_cluster" {
    value = "\nexport DOCKER_HOST=tcp://${openstack_networking_floatingip_v2.atx2016_swarm.address}:2375\nexport DOCKER_TLS_VERIFY=1\nexport DOCKER_CERT_PATH=${path.module}/files/ssl"
}
