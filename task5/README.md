# Task 5: Промпт-инжиниринг и работа с логами Nginx

Проект для автоматизации работы с логами Nginx, анализа с использованием LLM и настройки инфраструктуры (AWS/KVM).

## Описание проекта

Проект реализует систему мониторинга и анализа логов Nginx с использованием:
- Bash-скриптов для обработки логов
- Systemd демона для непрерывной записи логов
- Python-скрипта с интеграцией Gemini API для интеллектуального анализа логов
- Скриптов автоматизации развертывания на AWS EC2 и KVM виртуальных машинах

## Структура проекта

```
task5/
├── init.sh                    # Главный скрипт инициализации и настройки
├── task.md                    # Описание задачи
├── analyzer_reply.md          # Пример результата анализа логов
├── scripts/
│   ├── aws-instance.sh        # Скрипт создания и настройки AWS EC2 инстанса
│   └── kvm-instance.sh        # Скрипт создания и настройки KVM виртуальной машины
└── src/
    ├── llm-analyzer.py        # Python-скрипт для анализа логов через Gemini API
    ├── log_daemon.sh          # Демон для обработки логов Nginx
    ├── log_daemon.service     # Systemd unit файл для демона
    ├── promt_file.txt         # Шаблон промпта для анализа логов
    └── requirements.txt       # Python зависимости
```

## Основные компоненты

### 1. init.sh

Главный скрипт инициализации, поддерживающий три режима работы:

- **KVM** - создание и настройка виртуальной машины на KVM
- **AWS** - создание и настройка инстанса на AWS EC2
- **INSTANCE** - настройка окружения на уже запущенном инстансе

**Функции:**
- `configureInstance()` - основная функция настройки инстанса:
  - Установка пакетов (nginx, htop, ttyd, python3.12-venv)
  - Настройка Nginx с проксированием htop через ttyd
  - Установка и запуск демона обработки логов
  - Настройка анализатора логов на базе LLM
- `awsInstance()` - управление AWS EC2 инстансом
- `kvmInstance()` - управление KVM виртуальной машиной
- `connectToInstance()` - подключение к инстансу по SSH и копирование файлов

**Использование:**
```bash
./init.sh --mode KVM    # Запуск в режиме KVM (требует sudo)
./init.sh --mode AWS    # Запуск в режиме AWS
```

### 2. log_daemon.sh

Демон для обработки логов Nginx, выполняющий следующие задачи:

- Чтение последних 50 строк из `/var/log/nginx/access.log` каждые 5 секунд
- Запись всех логов в `file1.log`
- Автоматическая очистка `file1.log` при превышении 300 КБ
- Логирование информации об очистках в `file2.log` (дата, время, количество удалённых записей)
- Фильтрация и запись логов с кодами 5xx в `file3.log`
- Фильтрация и запись логов с кодами 4xx в `file4.log`

**Расположение файлов:**
- `/tmp/nginx_logger_daemon/file1.log` - основной файл логов
- `/tmp/nginx_logger_daemon/file2.log` - журнал очисток
- `/tmp/nginx_logger_daemon/file3.log` - логи с ошибками 5xx
- `/tmp/nginx_logger_daemon/file4.log` - логи с ошибками 4xx

**Технологии:** Bash, sed, awk

### 3. log_daemon.service

Systemd unit файл для автоматического запуска и управления демоном:

- Автоматический запуск после загрузки системы
- Автоматический перезапуск при завершении процесса
- Запуск от имени root

**Установка:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable log-daemon.service
sudo systemctl start log-daemon.service
```

### 4. llm-analyzer.py

Python-скрипт для интеллектуального анализа логов Nginx с использованием Google Gemini API.

**Возможности:**
- Анализ логов по пользовательскому промпту из файла
- Настройка параметров генерации (temperature, top_p)
- Поддержка плейсхолдера `{logs}` в промпте для подстановки содержимого логов

**Зависимости:**
- `google-generativeai` - клиент для Gemini API
- `python-dotenv` - загрузка переменных окружения

**Использование:**
```bash
python3 llm-analyzer.py \
    --logfile /tmp/nginx_logger_daemon/file4.log \
    --promptfile promt_file.txt \
    --temperature 0.2 \
    --top_p 0.9
```

**Параметры:**
- `--logfile` - путь к файлу с логами (обязательный)
- `--promptfile` - путь к файлу с промптом, содержащим `{logs}` (обязательный)
- `--temperature` - параметр случайности (0.0-2.0, по умолчанию 0.2)
- `--top_p` - параметр nucleus sampling (0.0-1.0, по умолчанию 1.0)

**Настройка API ключа:**
```bash
export GOOGLE_API_KEY="your_api_key_here"
# или создать файл .env с содержимым:
# GOOGLE_API_KEY=your_api_key_here
```

### 5. promt_file.txt

Шаблон промпта для анализа логов, который выполняет:

1. Поиск запросов с кодом ответа 400
2. Группировку по IP-адресам клиентов
3. Подсчёт количества запросов для каждого IP
4. Анализ проблемных endpoints
5. Выявление аномалий и подозрительных закономерностей:
   - Высокая частота ошибок от одного IP
   - Повторяющиеся паттерны запросов
   - Необычные endpoints
   - Временные кластеры
   - Нестандартные методы или заголовки

### 6. scripts/aws-instance.sh

Скрипт для автоматического создания и настройки AWS EC2 инстанса:

**Функции:**
- Создание или использование существующей security group
- Настройка правил файрвола (порты 22, 80, 443)
- Создание или использование существующего key pair
- Запуск EC2 инстанса (Ubuntu 24.04, t2.micro)
- Получение публичного IP адреса

**Параметры:**
- `AMI_ID` - ID образа Ubuntu 24.04
- `INSTANCE_TYPE` - тип инстанса (t2.micro)
- `KEY_PAIR_NAME` - имя ключевой пары
- `SECURITY_GROUP_NAME` - имя security group

### 7. scripts/kvm-instance.sh

Скрипт для автоматического создания и настройки KVM виртуальной машины:

**Поддерживаемые дистрибутивы:**
- Ubuntu Noble (по умолчанию)
- Amazon Linux 2

**Функции:**
- Установка необходимых пакетов (libvirt, qemu, virt-install и др.)
- Скачивание cloud image
- Создание виртуального диска
- Генерация SSH ключей
- Создание cloud-init конфигурации
- Установка и запуск виртуальной машины

**Использование:**
```bash
sudo ./scripts/kvm-instance.sh --full --dist ubuntu
```

**Параметры:**
- `--full` - полная установка
- `--dist` - дистрибутив (ubuntu/amazon)
- `--help` - справка
- `--debug` - отладочный режим

## Установка и настройка

### Предварительные требования

**Для локального запуска:**
- Python 3.12+
- pip
- bash
- Доступ к интернету для установки зависимостей

**Для AWS режима:**
- Установленный и настроенный AWS CLI
- Права на создание EC2 инстансов
- Настроенные credentials (`aws configure`)

**Для KVM режима:**
- Доступ с правами root (sudo)
- Поддержка виртуализации в процессоре
- KVM и libvirt установлены (скрипт установит автоматически)

### Быстрый старт

1. **Клонирование репозитория:**
```bash
cd /home/tsu/devops-trainee/task5
```

2. **Настройка переменных окружения:**
```bash
# Создать файл src/.env с API ключом Gemini
echo "GOOGLE_API_KEY=your_api_key_here" > src/.env
```

3. **Запуск в режиме KVM:**
```bash
./init.sh --mode KVM
```

4. **Запуск в режиме AWS:**
```bash
./init.sh --mode AWS
```

## Конфигурация Nginx

Проект настраивает Nginx с проксированием htop через ttyd:

- Порт: 80
- Location: `/htop/` → проксирование на `localhost:7681`
- Поддержка WebSocket для интерактивного терминала

## Мониторинг

### Просмотр логов демона

```bash
# Основной файл логов
tail -f /tmp/nginx_logger_daemon/file1.log

# Журнал очисток
cat /tmp/nginx_logger_daemon/file2.log

# Ошибки 5xx
tail -f /tmp/nginx_logger_daemon/file3.log

# Ошибки 4xx
tail -f /tmp/nginx_logger_daemon/file4.log
```

### Статус демона

```bash
sudo systemctl status log-daemon.service
```

### Запуск анализа логов

```bash
cd src
source venv/bin/activate
python3 llm-analyzer.py \
    --logfile /tmp/nginx_logger_daemon/file4.log \
    --promptfile promt_file.txt \
    --temperature 0.2
```

## Задачи проекта

### Раздел 1: Nginx, bash и Python

- ✅ Задача 1.1: Вывод загрузки CPU на страницу Nginx в реальном времени (htop через ttyd)
- ✅ Задача 1.2: Демон для обработки логов Nginx с фильтрацией и ротацией
- ✅ Задача 1.3: Анализ логов с использованием LLM (Gemini API)

### Раздел 2: Процессы, диски и файловая система

Задачи выполняются вручную на инстансе:
- Просмотр и управление процессами
- Работа с зомби-процессами
- Анализ использования дисков и inodes
- Работа с открытыми файлами

## Примеры использования

### Анализ логов с разными параметрами

```bash
# Консервативный анализ (низкая случайность)
python3 llm-analyzer.py \
    --logfile file4.log \
    --promptfile promt_file.txt \
    --temperature 0.1 \
    --top_p 0.8

# Более креативный анализ
python3 llm-analyzer.py \
    --logfile file4.log \
    --promptfile promt_file.txt \
    --temperature 0.5 \
    --top_p 0.95
```

### Управление демоном

```bash
# Остановка демона (создать stop файл)
touch /tmp/nginx_logger_daemon/stop_nginx_logger_daemon

# Перезапуск демона
sudo systemctl restart log-daemon.service

# Просмотр логов systemd
sudo journalctl -u log-daemon.service -f
```

## Структура логов Nginx

Проект работает с стандартным форматом access.log Nginx:
```
IP - - [timestamp] "METHOD /path HTTP/version" status_code size "referer" "user-agent"
```

## Troubleshooting

### Демон не запускается
- Проверьте права на файлы: `sudo chmod +x /usr/local/bin/log-daemon.sh`
- Проверьте статус: `sudo systemctl status log-daemon.service`
- Просмотрите логи: `sudo journalctl -u log-daemon.service`

### LLM анализатор не работает
- Убедитесь, что установлен API ключ: `echo $GOOGLE_API_KEY`
- Проверьте файл .env в директории src
- Проверьте установку зависимостей: `pip list | grep google-generativeai`

### Проблемы с AWS/KVM
- Для AWS: проверьте credentials и права доступа
- Для KVM: убедитесь, что запускаете с sudo и виртуализация включена

## Автор

Проект создан в рамках обучения DevOps (Task 5).

## Лицензия

Проект предназначен для образовательных целей.

