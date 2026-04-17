#!/bin/bash

# Установка и настройка только GOST (без Byedpi)
# Исправленная версия с правильной структурой директорий

echo "Подготовка к установке ONLY GOST"

# Создание директории проекта
rm -rf gost-setup
mkdir -p gost-setup
cd gost-setup

# Скачивание и сборка GOST
echo "Скачивание и сборка GOST..."
git clone https://github.com/go-gost/gost.git
cd gost/cmd/gost
go build
if [ $? -eq 0 ]; then
    echo "GOST успешно собран"
    # Создаем директорию bin и копируем туда бинарник
    mkdir -p ../../../bin
    cp gost ../../../bin/gost
else
    echo "Ошибка сборки GOST"
    exit 1
fi
cd ../../..

# Проверка, что бинарный файл GOST создан
if [ ! -f "bin/gost" ]; then
    echo "Ошибка: Не удалось создать бинарный файл GOST"
    exit 1
fi

echo "Бинарный файл GOST успешно создан в bin/"

# Создание Dockerfile для GOST
echo "Создание Dockerfile для GOST..."
cat > Dockerfile << 'EOF'
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    openssl \
    tzdata \
    nano \
    && rm -rf /var/lib/apt/lists/*
RUN adduser --disabled-password --shell /bin/sh gostuser
RUN mkdir -p /etc/gost /usr/local/bin
COPY bin/gost /usr/local/bin/gost
COPY gost.yml /etc/gost/
RUN chmod +x /usr/local/bin/gost
EXPOSE 1081 8085
RUN echo '#!/bin/sh\n\
/usr/local/bin/gost -C /etc/gost/gost.yml' > /start.sh && chmod +x /start.sh
ENTRYPOINT ["/bin/sh", "/start.sh"]
EOF

# Создание конфигурационного файла GOST
echo "Создание конфигурационного файла GOST..."

cat > gost.yml << 'EOF'
# cat /etc/gost/gost.yml 
services:
- name: service-0
  addr: ":1081"
  handler:
    type: socks5
    metadata:
      udp: true  # Разрешаем клиентам подключаться по UDP
  listener:
    type: tcp    # Слушаем входящие соединения по TCP
log:
  output: stderr
  level: debug

api:
  addr: ":8085"
  accesslog: true
EOF

# Сборка Docker контейнера только для GOST
echo "Сборка Docker контейнера для GOST..."
docker build -t gost-only .

# Проверка успешности сборки
if [ $? -eq 0 ]; then
    echo "Docker контейнер для GOST успешно собран"
    
    echo "Проверка файлов в контейнере..."
    # Простая проверка, что бинарники существуют, но без запуска контейнера
    docker run --rm --entrypoint ls gost-only -la /usr/local/bin/ || echo "Ошибка проверки контейнера"
    
    # Запуск контейнера
    echo "Запуск контейнера GOST..."
    docker run -d \
      --name gost-only-container \
      -p 1081:1081 \
      -p 8085:8085 \
      gost-only
    
    echo "Установка GOST завершена!"
    echo "Система готова к использованию через SOCKS5 прокси на порту 1081"
    echo "API доступен на порту 8085"
    echo "Для проверки работы используйте: docker logs gost-only-container"
    
else
    echo "Ошибка сборки Docker контейнера для GOST"
    exit 1
fi

echo -e "$(cat <<EOF

\033[1;36m\|/          (__)    \033[0m
\033[1;36m     \`\------(oo)\033[0m
\033[1;36m       ||    (__)     VAMA-WAMA-VAMA-WAMA CHOOOOMO\033[0m
\033[1;36m       ||w--||     \|/\033[0m
\033[1;36m   \|/\033[0m

DONE!

EOF
)"
