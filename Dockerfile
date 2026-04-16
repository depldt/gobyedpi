FROM docker.io/alpine:latest
RUN apk add --no-cache ca-certificates openssl
RUN adduser -D -s /bin/sh gostuser
RUN mkdir -p /etc/gost /etc/byedpi
# Копирование файлов
COPY gost /usr/local/bin/gost
COPY ciadpi /usr/local/bin/ciadpi
COPY gost.yml /etc/gost/
COPY byedpi.conf /etc/byedpi/
RUN chmod +x /usr/local/bin/gost /usr/local/bin/ciadpi
EXPOSE 8080 8081 8082
ENTRYPOINT ["/usr/local/bin/gost", "-C", "/etc/gost/gost.yml"]
