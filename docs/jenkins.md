## Run Jenkins:

```
ssh -F ssh_config swarm

docker pull 127.0.0.1:5000/jenkins-demo

docker run -d --name jenkins -p 8080:8080 127.0.0.1:5000/jenkins-demo
docker exec -ti jenkins bash
```




