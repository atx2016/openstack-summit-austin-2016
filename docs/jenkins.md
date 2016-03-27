## Run Jenkins:

```
ssh -F ssh_config swarm
docker run -d --name jenkins -p 8080:8080 jenkins
docker exec -ti jenkins bash
mkdir extras
curl -sSL http://deis.io/deis-cli/install.sh | sh
./deis login http://deis.xxxxxxxx
```


