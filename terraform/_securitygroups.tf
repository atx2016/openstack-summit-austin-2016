resource "openstack_compute_secgroup_v2" "atx2016" {
  name = "${var.cluster_name}_atx2016"
  description = "${var.cluster_name} - Austin 2016 Demo"
  # INTERNAL Communication only
  rule {
    ip_protocol = "icmp"
    from_port = "-1"
    to_port = "-1"
    self = true
  }
  rule {
    ip_protocol = "tcp"
    from_port = "1"
    to_port = "65535"
    self = true
  }
  rule {
    ip_protocol = "udp"
    from_port = "1"
    to_port = "65535"
    self = true
  }
}

resource "openstack_compute_secgroup_v2" "atx2016_swarm" {
  name = "${var.cluster_name}_atx2016_swarm"
  description = "${var.cluster_name} - Austin 2016 Demo"
  # SSH
  rule {
    ip_protocol = "tcp"
    from_port = "22"
    to_port = "22"
    cidr = "${var.whitelist_network}"
  }
  # DOCKER SWARM
  rule {
    ip_protocol = "tcp"
    from_port = "2375"
    to_port = "2375"
    cidr = "${var.whitelist_network}"
  }
  # DANGER DANGER DANGER
  # Uncomment these if you want to allow
  # unrestricted inbound access
  #rule {
  #  ip_protocol = "tcp"
  #  from_port = "1"
  #  to_port = "65535"
  #  cidr = "${var.whitelist_network}"
  #}
  #rule {
  #  ip_protocol = "udp"
  #  from_port = "1"
  #  to_port = "65535"
  #  cidr = "${var.whitelist_network}"
  #}
}

resource "openstack_compute_secgroup_v2" "atx2016_deis" {
    name = "${var.cluster_name}_atx2016_deis"
    description = "Deis Security Group"
    rule {
        ip_protocol = "tcp"
        from_port = "22"
        to_port = "22"
        cidr = "0.0.0.0/0"
    }
    rule {
        ip_protocol = "tcp"
        from_port = "2222"
        to_port = "2222"
        cidr = "0.0.0.0/0"
    }
    rule {
        ip_protocol = "tcp"
        from_port = "80"
        to_port = "80"
        cidr = "0.0.0.0/0"
    }
    rule {
        ip_protocol = "icmp"
        from_port = "-1"
        to_port = "-1"
        cidr = "0.0.0.0/0"
    }
}
