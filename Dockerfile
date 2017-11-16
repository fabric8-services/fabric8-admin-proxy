FROM centos:7
LABEL maintainer="Aslak Knutsen <aslak@redhat.com>"

ENV VERSION=v1.4.3

RUN curl -L https://github.com/containous/traefik/releases/download/${VERSION}/traefik_linux-amd64 > /usr/local/traefik && chmod +x /usr/local/traefik

EXPOSE 8080
EXPOSE 8082

ENTRYPOINT ["/usr/local/traefik"]