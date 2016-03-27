variable "cluster_size" {
    default = 3
}

variable "cluster_name" {
    default = "testing"
}

variable "swarm_version" {
    default = "latest"
}

variable "generate_ssl" {
  description = "set to 0 if you want to reuse ssl certs"
  default = 1
}

variable "fqdn" {
  description = "Fully Qualified DNS to add to TLS certs"
  default = "swarm.example.com"
}

variable "docker_registry_version" {
    description = "version of docker registry to use. Should be 2 or higher."
    default = "2"
}

variable "swift_container" {
  description = "swift container for docker registry"
  default = "docker_registry"
}
