FROM jumanjiman/caddy

ADD . /demo

WORKDIR /demo/presentation

CMD ["-conf", "/demo/presentation/caddyfile", "-root", "/demo/presentation"]

EXPOSE 8080
