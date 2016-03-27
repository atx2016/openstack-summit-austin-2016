# LBAAS v2

Terraform does not support LBaaS v2 ( an excellent example of how openstack is slow to support its ecosystem ).

This is a rough guide on how I set up LBAAS v2 for the demo.


## Before running terraform

I reserved a floating IP and pointed a wildcard DNS in my domain at it ( *.atx2016.paulcz.net )

I set up TF variables to use this FQDN:

```
export TF_VAR_fqdn="atx2016.paulcz.net"
export TF_VAR_deis_domain="atx2016.paulcz.net"
```

## After running terraform

Create LB

```
neutron lbaas-loadbalancer-create --name atx2016_prod subnet_production-atx2016
neutron lbaas-loadbalancer-show atx2016_prod 
```

Give it a floating IP and Security groups:

```
export LBAAS_PORT=ed8eeca8-b00c-4405-add5-aa2746fd873f
neutron port-update --security-group production_atx2016 $LBAAS_PORT
neutron port-update --security-group production_atx2016_deis $LBAAS_PORT
neutron port-update --security-group production_atx2016_swarm $LBAAS_PORT
neutron floatingip-associate  a9698981-5d65-4607-87b8-15846a0ef9a7 ed8eeca8-b00c-4405-add5-aa2746fd873f
```

Create listeners and pools:

```
neutron lbaas-listener-create --loadbalancer atx2016_prod --protocol HTTP --protocol-port 80 --name deis_http
neutron lbaas-listener-create --loadbalancer atx2016_prod --protocol TCP --protocol-port 2222 --name deis_git
neutron lbaas-listener-create --loadbalancer atx2016_prod --protocol TCP --protocol-port 2375 --name swarm

neutron lbaas-pool-create --lb-algorithm SOURCE_IP --listener deis_http --protocol HTTP --name deis_http
neutron lbaas-pool-create --lb-algorithm SOURCE_IP --listener deis_git --protocol TCP --name deis_git
neutron lbaas-pool-create --lb-algorithm SOURCE_IP --listener swarm --protocol TCP --name swarm
```

Add members for swarm:

```
neutron lbaas-member-create  --subnet subnet_production-atx2016 --address 192.168.100.4 --protocol-port 2375 swarm
neutron lbaas-member-create  --subnet subnet_production-atx2016 --address 192.168.100.5 --protocol-port 2375 swarm
neutron lbaas-member-create  --subnet subnet_production-atx2016 --address 192.168.100.6 --protocol-port 2375 swarm
```

Add members for deis:

_only add the server running builder to the git_

```
neutron lbaas-member-create  --subnet subnet_production-atx2016 --address 192.168.100.7 --protocol-port 80 deis_http
neutron lbaas-member-create  --subnet subnet_production-atx2016 --address 192.168.100.8 --protocol-port 80 deis_http
neutron lbaas-member-create  --subnet subnet_production-atx2016 --address 192.168.100.9 --protocol-port 80 deis_http

neutron lbaas-member-create  --subnet subnet_production-atx2016 --address 192.168.100.7 --protocol-port 2222 deis_git

```

Add member for jenkins:

_once jenkins is online lets add its host:_

```
neutron lbaas-listener-create --loadbalancer atx2016_prod --protocol HTTP --protocol-port 8080 --name jenkins
neutron lbaas-pool-create --lb-algorithm SOURCE_IP --listener jenkins --protocol HTTP --name jenkins

neutron lbaas-member-create  --subnet subnet_production-atx2016 --address 192.168.100.7 --protocol-port 8080 jenkins
```
