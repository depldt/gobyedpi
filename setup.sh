#!/bin/bash

# cd ~
cd ~
# Установка GOST + Byedpi DPI обхода

echo "Подготовка к установке GOST + Byedpi DPI обхода"

# Создание директории проекта
mkdir -p gost-byedpi-setup
cd gost-byedpi-setup

# Скачивание исходных кодов
echo "Скачивание исходных кодов GOST..."
git clone https://github.com/go-gost/gost.git
cd gost/cmd/gost
go build
cp gost ../../../gost
cd ../../..

echo "Скачивание исходных кодов Byedpi..."
git clone https://github.com/hufrea/byedpi.git
cd byedpi
make
cp ciadpi ../ciadpi
cd ..

# Создание Dockerfile
echo "Создание Dockerfile..."
cat > Dockerfile << 'EOF'
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
EOF

# Создание конфигурационного файла GOST
echo "Создание конфигурационного файла GOST..."
cat > gost.yml << 'EOF'
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp
    chain: chain-0
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: "127.0.0.1:8081"
      connector:
        type: direct
      dialer:
        type: tcp
        tls:
          insecure: true

log:
  output: stderr
  level: debug

api:
  addr: ":18080"
  pathPrefix: /api
  accesslog: true
EOF

# Создание конфигурационного файла Byedpi
echo "Создание конфигурационного файла Byedpi..."
cat > byedpi.conf << 'EOF'
-Kt,h -n ya.ru -f7 --md5sig -d1 -s0+s -s3+s -s6+s -s9+s -s12+s -s15+s -s20+s -o10000+s -s30+s -An -Ku -a5 -An
-Kt,h -n www.google.com -d 1+s -O 1 -s 25+s -t 5 -An -Ku -a5 -An
-Kt,h -n www.google.com -d 1+s -O 1 -s 29+s -t 5 -An -Ku -a5 -An
EOF

# Сборка Docker контейнера
echo "Сборка Docker контейнера..."
docker build -t gost-byedpi .

# Запуск контейнера
echo "Запуск контейнера..."
docker run -d \
  --name gost-byedpi-container \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  gost-byedpi

echo "Установка завершена!"
echo "Система готова к использованию через прокси на порту 8080"
echo "Для проверки работы используйте: docker logs gost-byedpi-container"
