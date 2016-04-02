FROM jumanjiman/caddy

ADD . /demo

WORKDIR /demo/presentation

ENTRYPOINT ["/usr/sbin/caddy", "-conf", "/demo/presentation/caddyfile", "-root", "/demo/presentation"]

EXPOSE 8080
