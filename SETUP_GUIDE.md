# Установка и настройка GOST + Byedpi DPI обхода

## Введение

Это подробное руководство по установке и настройке комплексного решения для обхода интернет-цензуры с использованием GOST и Byedpi. Решение специально адаптировано для работы в среде Docker на Alpine Linux.

## Предварительные требования

Перед началом установки убедитесь, что у вас установлен:
- Docker (последняя версия)
- Базовые знания работы с командной строкой
- Доступ к интернет-ресурсам для загрузки файлов

## Шаг 1: Подготовка директории проекта

Создайте директорию для проекта и перейдите в нее:
```bash
mkdir gost-byedpi-setup
cd gost-byedpi-setup
```

## Шаг 2: Загрузка необходимых файлов

Если у вас нет файлов GOST и Byedpi, загрузите их:

Для GOST (вам нужно скомпилировать или скачать бинарник):
```bash
# Скачайте исходный код GOST
git clone https://github.com/go-gost/gost.git
cd gost/cmd/gost
go build
# Скопируйте получившийся файл в директорию проекта
cp gost ../../../gost
cd ../../../
```

Для Byedpi:
```bash
# Скачайте исходный код Byedpi
git clone https://github.com/hufrea/byedpi.git
cd byedpi
make
# Скопируйте получившийся файл в директорию проекта
cp ciadpi ../ciadpi
cd ..
```

## Шаг 3: Создание Dockerfile

Создайте файл `Dockerfile` со следующим содержимым:

```dockerfile
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
```

## Шаг 4: Создание конфигурационного файла GOST

Создайте файл `gost.yml` в директории проекта:

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

## Шаг 5: Создание конфигурационного файла Byedpi

Создайте файл `byedpi.conf` в директории проекта:

```conf
-Kt,h -n ya.ru -f7 --md5sig -d1 -s0+s -s3+s -s6+s -s9+s -s12+s -s15+s -s20+s -o10000+s -s30+s -An -Ku -a5 -An
-Kt,h -n www.google.com -d 1+s -O 1 -s 25+s -t 5 -An -Ku -a5 -An
-Kt,h -n www.google.com -d 1+s -O 1 -s 29+s -t 5 -An -Ku -a5 -An
```

## Шаг 6: Сборка Docker контейнера

Соберите Docker контейнер командой:
```bash
docker build -t gost-byedpi .
```

## Шаг 7: Запуск контейнера

Запустите контейнер с указанием портов:
```bash
docker run -d \
  --name gost-byedpi-container \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  gost-byedpi
```

## Шаг 8: Проверка работы

Проверьте, запущен ли контейнер:
```bash
docker ps
```

Вы должны увидеть `gost-byedpi-container` в списке запущенных контейнеров.

## Использование системы

1. Установите прокси в клиентском приложении:
   - Адрес: `localhost` (или ваш IP)
   - Порт: `8080`

2. Все сетевые запросы будут автоматически обрабатываться через систему GOST + Byedpi

## Проверка логов

Для мониторинга работы системы используйте:
```bash
docker logs gost-byedpi-container
```

## Управление контейнером

Остановить контейнер:
```bash
docker stop gost-byedpi-container
```

Запустить контейнер заново:
```bash
docker start gost-byedpi-container
```

## Как работает система

1. Клиентское приложение отправляет запрос через прокси на порт 8080
2. GOST принимает запрос и передает его в Byedpi через внутренний порт 8081
3. Byedpi применяет методы обхода DPI к трафику (десинхронизации, обфускация)
4. Запрос направляется в интернет с обходом ограничений

## Адаптация для разных систем

### Для Windows:
Если вы используете Windows, убедитесь, что Docker Desktop установлен и запущен.
Файлы с конфигурациями должны быть в формате Unix (LF), не Windows (CRLF).

### Для macOS:
Процесс аналогичен Linux. Убедитесь, что Docker Desktop установлен.

## Решение проблем

### Проблема с доступом к портам:
Если возникают ошибки доступа к портам 8080, 8081, 8082, проверьте:
```bash
netstat -tulpn | grep :8080
```

### Проблема с Docker:
Если Docker не запускается:
```bash
systemctl start docker
systemctl enable docker
```

## Безопасность

⚠️ **Это руководство создано исключительно в образовательных целях.**
- Используйте эти инструменты ответственно и в соответствии с законом вашей страны
- Обратите внимание, что использование этих методов может быть незаконным
- Все изменения изолированы в контейнере, поэтому они не затрагивают вашу основную систему

## Лицензия

MIT License
