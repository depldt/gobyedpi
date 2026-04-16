# GOST + Byedpi DPI обход

Комплексное решение для обхода интернет-цензуры с использованием GOST и Byedpi

## Описание проекта

Этот проект предоставляет полное решение для обхода DPI (Deep Packet Inspection) ограничений с использованием двух мощных инструментов:
- **GOST** - мощный прокси-сервер с возможностью обфускации
- **Byedpi** - инструмент для обхода сетевых проверок

Система позволяет обходить ограничения для приложений, использующих UDP трафик.

## Структура проекта

```
.
├── README.md              # Это руководство
├── Dockerfile             # Файл сборки Docker контейнера
├── gost.yml               # Конфигурация GOST прокси
├── byedpi.conf            # Конфигурация Byedpi
├── gost                   # Бинарный файл GOST
└── ciadpi                 # Бинарный файл Byedpi
```

## Установка

### Предварительные требования

- Docker
- Базовые знания работы с командной строкой

### Шаги установки

1. Создайте папку для проекта:
```bash
mkdir gost-byedpi-setup
cd gost-byedpi-setup
```

2. Скопируйте все файлы проекта в эту папку

3. Соберите Docker контейнер:
```bash
docker build -t gost-byedpi .
```

4. Запустите контейнер:
```bash
docker run -d \
  --name gost-byedpi-container \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  gost-byedpi
```

## Конфигурация

### gost.yml - Конфигурация GOST

```yaml
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
```

### byedpi.conf - Конфигурация Byedpi

```conf
-Kt,h -n ya.ru -f7 --md5sig -d1 -s0+s -s3+s -s6+s -s9+s -s12+s -s15+s -s20+s -o10000+s -s30+s -An -Ku -a5 -An
-Kt,h -n www.google.com -d 1+s -O 1 -s 25+s -t 5 -An -Ku -a5 -An
-Kt,h -n www.google.com -d 1+s -O 1 -s 29+s -t 5 -An -Ku -a5 -An
```

## Использование

1. После запуска контейнер будет доступен по адресу:
   - `http://localhost:8080` - основной прокси-порт

2. Настройте клиентское приложение на использование HTTP прокси:
   - Адрес: `localhost`
   - Порт: `8080`

3. Все сетевые запросы будут автоматически обрабатываться GOST и Byedpi

## Система работы

1. Клиент отправляет запрос через GOST прокси
2. GOST передает запрос через Byedpi (через внутренний порт)
3. Byedpi применяет методы обхода ограничений к трафику UDP/TCP
4. Запрос направляется в интернет

## Команды управления

Посмотреть запущенные контейнеры:
```bash
docker ps
```

Просмотр логов:
```bash
docker logs gost-byedpi-container
```

Остановить контейнер:
```bash
docker stop gost-byedpi-container
```

Запустить заново:
```bash
docker start gost-byedpi-container
```

## Важное замечание

⚠️ **Это руководство создано исключительно в образовательных целях.**
- Используйте эти инструменты ответственно
- Убедитесь, что ваше использование соответствует законам вашей страны
- Обратите внимание, что использование этих методов может быть незаконным в вашем регионе

## Лицензия

MIT License
