# Instructions for spinning up infrastructure for Demo

## Requirements

* Terraform
* Docker
* deis-cli

## Getting Started

Source your stackrc file and pass it into TF Vars:

```
. ~/demo.stackrc
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

export TF_VAR_username=${OS_USERNAME} 
export TF_VAR_password=${OS_PASSWORD}
export TF_VAR_tenant=${OS_TENANT_NAME}
export TF_VAR_auth_url=${OS_AUTH_URL}
```


Restrict access to just your IP address:

_Skip if you want to leave it open to the world_

```
export TF_VAR_whitelist_network=$(curl -s icanhazip.com)/32
```

Set a network CIDR for your neutron network:

_Make sure it's unique in the tenant_

```
export TF_VAR_network_cidr="192.168.199.0/24"
```

Set the path to your public key (skip if it's `~/.ssh/id_rsa.pub`):

```
export TF_VAR_public_key_path="<path_to_your_pubkey>"
```

Set your cluster name (it should be unique to tenant):

```
export TF_VAR_cluster_name="${USERNAME}"
```

## Deploy Infrastructure

This will create a 3 node Docker Swarm Cluster and a 3 node DEIS cluster

```
cd terraform
terraform plan
terraform apply
```

Terraform will provide instructions on how to set up environment variables for Swarm, and the URL to register your first DEIS user against.

```
Outputs:

  msg           = SSH to deis and run `deisctl install platform && deisctl start platform`
  register      = Run the following to register your first [admin] user: $ deis register http://deis.xxx.xxx.xxx.xxx.xip.io
  swarm_cluster = 
export DOCKER_HOST=tcp://xxx.xxx.xxx.xxx:2375
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH=/path/to/openstack-summit-austin-2016/terraform/files/ssl

```

The first server of each cluster will get a floating IP and be accessible via an ssh_config file that has been written to disk:

```
ssh -F ssh_config deis
ssh -F ssh_config swarm
```


## Run Jenkins:

```
ssh -F ssh_config swarm

docker run -d -p 8080:8080 jenkins
```
