# Развертывание инфраструктуры с Vagrant & Libvirt (KVM)

Данный каталог содержит конфигурацию для локального поднятия виртуальных машин на Ubuntu с использованием связки **Vagrant** + **KVM (Libvirt)**.

---

## Хроники импортозамещения и troubleshooting (как это было собрано)

Развертывание стандартными методами упирается в закрытые репозитории и гео-блокировки со стороны HashiCorp. Ниже — критические проблемы и решения, найденные в процессе настройки. Именно поэтому «просто `vagrant up`» из коробки в РФ часто выдает пачку 404-х ошибок.

### 1. Установка плагина `vagrant-libvirt` (обход мёртвых репозиториев и Бундлера)

**Проблема:** Команда `vagrant plugin install` ломается с ошибкой `404 Not Found`, так как Vagrant по умолчанию запрашивает гемы с выключенного сервера `gems.hashicorp.com`. Ручная правка локальных `Gemfile` игнорируется внутренним Бундлером Vagrant — отсюда ощущение, что «ничего не помогает», пока не перенаправить источник на уровне самой команды установки плагина.

**Решение:** Полная очистка дефолтных источников и принудительное перенаправление на живой реестр RubyGems:

```bash
vagrant plugin install vagrant-libvirt --plugin-clean-sources --plugin-source https://rubygems.org
```

> **Заметка на полях:** Процесс сборки может занимать до 10 минут. Плагин компилирует нативные C-расширения (`racc`, `ruby-libvirt`), для которых нужны системные пакеты компилятора (`gcc`, `make`) и библиотеки разработки (`libvirt-dev`). Гем `nokogiri` (XML-парсер для KVM) часто скачивается уже скомпилированным под архитектуру `x86_64-linux-gnu`, что экономит время.

### 2. Конфликт storage pool в KVM

**Проблема:** Ошибка `Call to virStoragePoolDefineXML failed: operation failed: Storage source conflict with pool: 'images'`. Плагин пытается создать свой пул `default`, смотрящий в `/var/lib/libvirt/images`, но в Ubuntu этот путь уже занят системным пулом `images`.

**Решение:** Явное указание Vagrant использовать существующий пул в блоке провайдера:

```ruby
lv.storage_pool_name = "images"
```

### 3. Обход гео-блокировки Vagrant Cloud (404 при скачивании боксов)

**Проблема:** Запросы к `vagrantcloud.com` для скачивания образов (boxes) блокируются по IP для региона РФ, возвращая ложную ошибку `404`. Зеркало Яндекса (`mirror.yandex.ru/ubuntu-cloud-images/vagrant/`) заброшено в 2019 году и содержит только древние релизы (Trusty/Precise).

**Решение:** Независимое российское зеркало API Vagrant Cloud от команды Elab и образ **Bento** (от Chef) с поддержкой Libvirt из коробки. В начало `Vagrantfile` добавляется подмена переменной окружения:

```ruby
ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'
```

---

## Эталонный конфигурационный файл (`Vagrantfile`)

Текущая рабочая конфигурация в репозитории:

```ruby
# Подмена дефолтного заблокированного облака на зеркало в РФ
ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'

Vagrant.configure("2") do |config|
    # Проверка наличия плагина перед стартом
    config.vagrant.plugins = ["vagrant-libvirt"]

    # Чистый образ Ubuntu 24.04 LTS (Noble Numbat) от проекта Bento
    config.vm.box = "bento/ubuntu-24.04"

    # Тонкая настройка гипервизора KVM/Libvirt
    config.vm.provider :libvirt do |lv|
        lv.cpus = 1
        lv.memory = 1024                         # выделяемая ОЗУ в МБ
        lv.storage_pool_name = "images"          # интеграция в системный пул Ubuntu
    end
end
```

---

## Базовое взаимодействие (шпаргалка команд)

Управление жизненным циклом виртуалки — из директории с `Vagrantfile`:

| Команда | Назначение |
|--------|------------|
| `vagrant up` | Создать и запустить ВМ (при первом запуске скачает образ). |
| `vagrant ssh` | Войти в терминал ВМ (SSH по сгенерированным ключам). |
| `vagrant status` | Состояние: `running`, `poweroff`, `not created`. |
| `vagrant halt` | Корректное выключение ОС (graceful shutdown). |
| `vagrant reload` | Перезагрузка; применяет изменения в `Vagrantfile` без полного пересоздания. |
| `vagrant destroy` | Удалить ВМ и диски из пула Libvirt. |

---

## Гайд на будущее (DevOps-лайфхаки)

### 1. Бокс есть только под VirtualBox

Если на зеркале или в сети найден образ, но в метаданных только `provider: virtualbox`, его можно конвертировать под KVM плагином-мутатором (источник гемов — снова через RubyGems, не HashiCorp):

```bash
vagrant plugin install vagrant-mutate --plugin-clean-sources --plugin-source https://rubygems.org
vagrant box add имя_бокса /путь/к/файлу.box
vagrant mutate имя_бокса libvirt
```

### 2. Что внутри KVM без Vagrant

Vagrant — обёртка; сущности живут в libvirt. Проверка пулов и ВМ напрямую:

```bash
sudo virsh pool-list --all
sudo virsh list --all
```

### 3. Глобальные прокси на крайний случай

Если зеркало Elab недоступно, бокс можно скачать с официального сайта через `curl` с прокси и добавить локально:

```bash
curl -L -x http://IP:PORT -o noble.box https://app.vagrantcloud.com/...
vagrant box add локальное_имя noble.box
```

---

## Быстрый старт (после установки зависимостей)

```bash
cd OS-and-Networks/Vagrant
vagrant up
vagrant ssh
```

Перед первым `vagrant up` убедись, что установлены: KVM/libvirt, пакеты для сборки плагина (`libvirt-dev`, `gcc`, `make`) и плагин `vagrant-libvirt` с флагами `--plugin-clean-sources` и `--plugin-source https://rubygems.org`.
