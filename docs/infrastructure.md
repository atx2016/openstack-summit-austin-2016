# Instructions for spinning up infrastructure for Demo

## Requirements

* Terraform
* Docker
* stuff ?

## Getting Started

Source your stackrc file:

```
. ~/demo.stackrc
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

export TF_VAR_username=${OS_USERNAME} 
export TF_VAR_password=${OS_PASSWORD}
export TF_VAR_tenant=${OS_TENANT_NAME}
export TF_VAR_auth_url=${OS_AUTH_URL}
export TF_VAR_whitelist_network=$(curl -s icanhazip.com)/32
```

## Deploy Infrastructure

This will create a 3 node Docker Swarm Cluster and a 3 node DEIS cluster

```
cd terraform
terraform plan
terraform apply
```
