# Using DEIS

You've created your [infrastructure](infrastructure.md) now let's use it.

## Requirements:

* [DEIS cli](http://docs.deis.io/en/latest/using_deis/install-client/)

Ensure you have created your first (admin) user:

```
$ cd terraform
$ terraform show | tail 

Outputs:

DEIS = 
Run the following to register your first [admin] user: $ deis register http://deis.ip.of.deis.xip.io
swarm_cluster = 
export DOCKER_HOST=tcp://ip.of.swarm:2375
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH=/path/to/openstack-summit-austin-2016/terraform/files/ssl

$ deis register http://deis.ip.of.deis.xip.io
username: nope
password: 
password (confirm): 
email: nope@gmail.com
Registered nope
Logged in as nope

$ deis keys:add ~/.ssh/id_rsa.pub
Uploading id_rsa.pub to deis... done
```


## Deploy an Example App:

We have a Dockerfile based DEIS app built in this repo which will display the contents of [presentation/index.html](presentation/index.html) when run.  We can deploy this to DEIS:

```
$ deis create               
Creating Application... done, created ironic-bagpiper
Git remote deis added
remote available at ssh://git@deis.ip.of.deis.xip.io:2222/ironic-bagpiper.git

git push deis master           
Counting objects: 52, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (42/42), done.
Writing objects: 100% (52/52), 8.43 KiB | 0 bytes/s, done.
Total 52 (delta 10), reused 0 (delta 0)

-----> Building Docker image
remote: Sending build context to Docker daemon 15.36 kB
Step 0 : FROM alpine:3.3
3.3: Pulling from library/alpine
9a686d8dd34c: Pulling fs layer
9a686d8dd34c: Verifying Checksum
9a686d8dd34c: Download complete
9a686d8dd34c: Pull complete
Digest: sha256:1849e75e25b5a005781b32e7ce0ec2892c85ef3d40d76861a6d3c721f1acc353
Status: Downloaded newer image for alpine:3.3
 ---> 9a686d8dd34c
Step 1 : RUN apk add -U     bash    nginx   && rm -rf /var/cache/apk*
 ---> Running in e9dbc26014ca
fetch http://dl-cdn.alpinelinux.org/alpine/v3.3/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.3/community/x86_64/APKINDEX.tar.gz
(1/8) Installing ncurses-terminfo-base (6.0-r6)
(2/8) Installing ncurses-terminfo (6.0-r6)
(3/8) Installing ncurses-libs (6.0-r6)
(4/8) Installing readline (6.3.008-r4)
(5/8) Installing bash (4.3.42-r3)
Executing bash-4.3.42-r3.post-install
(6/8) Installing nginx-initscripts (1.8.0-r0)
Executing nginx-initscripts-1.8.0-r0.pre-install
(7/8) Installing pcre (8.38-r0)
(8/8) Installing nginx (1.8.1-r0)
Executing busybox-1.24.1-r7.trigger
OK: 14 MiB in 19 packages
 ---> 788d928b3c4d
Removing intermediate container e9dbc26014ca
Step 2 : RUN ln -sf /dev/stdout /var/log/nginx/access.log
 ---> Running in 32ae44ad66b9
 ---> 3d43e4ff3143
Removing intermediate container 32ae44ad66b9
Step 3 : RUN ln -sf /dev/stderr /var/log/nginx/error.log
 ---> Running in f2142df4ff86
 ---> 4a597dfaf7f0
Removing intermediate container f2142df4ff86
Step 4 : ENV POWERED_BY Deis
 ---> Running in d89be1e1361d
 ---> 51521e90c124
Removing intermediate container d89be1e1361d
Step 5 : COPY rootfs /
 ---> 03ee316d0de6
Removing intermediate container 219b152f5ec6
Step 6 : CMD /bin/boot
 ---> Running in 22cc3b66e08a
 ---> 4f253be9395c
Removing intermediate container 22cc3b66e08a
Step 7 : EXPOSE 80
 ---> Running in 3dd6616cfe55
 ---> b237969f6834
Removing intermediate container 3dd6616cfe55
Step 8 : ENV GIT_SHA 8ce32ac6c82dfe8f2dd8b4e79741fad053090932
 ---> Running in ec6ec072e08e
 ---> ae40d746d754
Removing intermediate container ec6ec072e08e
Successfully built ae40d746d754
-----> Pushing image to private registry

-----> Launching... 
       done, ironic-bagpiper:v2 deployed to Deis

       http://ironic-bagpiper.ip.of.deis.xip.io

       To learn more, use `deis help` or visit http://deis.io

To ssh://git@deis.ip.of.deis.xip.io:2222/ironic-bagpiper.git
 * [new branch]      master -> master

$ curl http://ironic-bagpiper.ip.of.deis.xip.io
Powered by Deis


```
