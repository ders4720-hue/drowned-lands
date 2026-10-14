---
type: Document
title: Развёртывание
description: Клонирование репозитория и настройка софта (Godot, OpenCode, OpenKnowledge, godot-mcp) для работы с AI-агентами на Linux и Windows.
tags:
  - развёртывание
  - linux
  - windows
  - opencode
  - openknowledge
  - godot
sources:
  - resource: ./rules.md
    title: Правила вики
generated:
  at: "2026-10-09T13:00:00Z"
status: draft
---

# 📘 Развёртывание проекта `drowned-lands-the`

Документ описывает настройку окружения для работы с AI-агентами (**OpenCode** в терминале и **Cline** в OpenKnowledge) над проектом *The Drowned Lands*. Окружение настраивается на двух операционных системах: **Linux** (рекомендуемая среда — она же рабочая машина проекта) и **Windows**. Общие шаги описаны один раз, различия вынесены в раздел «Различия по ОС».

> **Важно:** Godot не установлен в `PATH`, правила верификации, MCP-рабочий процесс, границы и правила работы агентов описаны в [Правилах работы с OpenCode](./opencode-rules.md) — читайте их перед началом.

---

## 📋 Предварительные требования

| Компонент | Версия | Ссылка |
|---|---|---|
| **ОС** | Linux (рекомендуется) или Windows 10/11 (x64) | — |
| **Git** | актуальная | [git-scm.com](https://git-scm.com/) |
| **Node.js** | **24+** | [nodejs.org](https://nodejs.org/) |
| **Python** | 3.11+ | [python.org/downloads](https://www.python.org/downloads/) |
| **Godot Engine** | **4.4+** (рекомендуется 4.7.2) | [godotengine.org](https://godotengine.org/download/) |
| **OpenKnowledge Desktop** | актуальная | [openknowledge.ai/download](https://openknowledge.ai/download) |

> **Важно:** при установке Python обязательно отметьте галочку **«Add Python to PATH»** (только на Windows).

> **Про Python:** если используется только `uv tool install godot-editor-mcp`, системный Python не обязателен — `uv` скачивает свою изолированную версию. Python нужен только для OpenKnowledge CLI, если запускаете его через `npx` без Desktop-приложения.

### Проверка

Запустите подходящую для вашей ОС консоль и выполните:

```bash
git --version
node --version
python --version
```

Все три команды должны вывести версии.

---

## 🚀 Запуск

Перед работой с проектом настройте окружение по [этим инструкциям](./deploy.md). Там описаны: клонирование репозитория, установка Godot / `godot-editor-mcp`, аддон Godot MCP, OpenKnowledge и проверка конфигурации агентов.

---

Эти шаги одинаковы для обеих систем: клонирование репозитория, настройка git, установка `uv` и `godot-editor-mcp`, аддон Godot MCP, OpenKnowledge, проверка `opencode.json` и `.gitignore`.

### Шаг 1: Клонирование репозитория

> Путь `~/drowned-lands-the` — пример. Клонируйте репозиторий в удобное место; все команды ниже выполняйте из корня репозитория.

```bash
git clone https://github.com/cyberprimitives/drowned-lands-the.git
cd drowned-lands-the
```

### Шаг 2: настройка git

Один раз на машине:

```bash
git config --global user.name "Ваше Имя"
git config --global user.email "your@email.com"
```

Email должен совпадать с тем, что привязан к аккаунту GitHub/GitLab, иначе коммиты не будут привязаны к вашему профилю.

---

### Шаг 3: установка `uv`

Скачайте установщик и запустите его в вашей консоли. После установки **перезапустите консоль**.

### Шаг 4: установка `godot-editor-mcp`

```bash
uv tool install godot-editor-mcp
```

Проверьте:

```bash
godot-editor-mcp --help
```

> MCP-сервер работает по протоколу **stdio** и не предназначен для ручного запуска. При запуске он может сразу начать слушать порт — закройте его через `Ctrl+C`.

> ⚠️ **Никогда не запускайте `godot-editor-mcp` вручную** из терминала. Его запускает только OpenCode как дочерний процесс. Ручной запуск конфликтует за порт 9080 с уже работающим сервером и вызывает бесконечный `reconnecting` в Godot.
>
> Если случайно запустили — закройте `Ctrl+C` и перезапустите OpenCode.

---

### Шаг 5: установка аддона Godot MCP

1. Откройте проект `drowned-lands-the` в **Godot 4.4+**.
2. Перейдите в **Project → Project Settings → Plugins**.
3. Найдите **Godot MCP** и поставьте галочку **Enable**.

---

### Шаг 6: установка OpenKnowledge

Скачайте и установите [OpenKnowledge Desktop](https://openknowledge.ai/download) для вашей ОС. После установки откройте приложение и укажите корень проекта:

```
~/drowned-lands-the
```

---

### Шаг 7: проверка `opencode.json`

Файл `opencode.json` уже лежит в корне проекта. **Не редактируйте его вручную** — OpenKnowledge добавит свою MCP-секцию автоматически при первом открытии проекта.

Убедитесь, что файл содержит обе записи:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "godot-mcp": {
      "type": "local",
      "command": ["godot-editor-mcp"],
      "enabled": true,
      "timeout": 30000
    },
    "open-knowledge": {
      "type": "local",
      "enabled": true,
      "command": ["npx", "-y", "@inkeep/open-knowledge@latest", "mcp"]
    }
  }
}
```

Проверьте, что `npx` доступен:

```bash
npx --version
```

---

### Шаг 8: проверка `.gitignore`

Файл `.gitignore` уже в репозитории и содержит всё необходимое:

```gitignore
# Godot 4
.godot/
/android/
export_presets.cfg

# OpenKnowledge local state
.ok/

# Node modules
node_modules/
```

Файл `.okignore` тоже в репозитории — он ограничивает Cline (агента внутри OpenKnowledge) только папкой `docs/`.

> **`.okignore` vs `.ok/`:** `.ok/` — локальное состояние OpenKnowledge (индексы, кэш), оно машинно-зависимо и **не коммитится**. `.okignore` — правила исключения для Cline, они общие для команды и **должны** быть в репозитории.

---

## 2️⃣ Различия по ОС

### Linux (рекомендуется)

**Godot.** Загрузите self-contained бинарник и положите его в `~/.local/godot.app/bin/godot`, затем добавьте его в `PATH`:

```bash
export GODOT=$HOME/.local/godot.app/bin/godot
```

Добавьте эту строку (или `export PATH="$HOME/.local/godot.app/bin:$PATH"`) в `~/.bashrc`, чтобы она применялась в новых сессиях.

> **Важно:** в `AGENTS.md` и `docs/opencode-rules.md` путь к Godot
> задаётся переменной окружения `$GODOT`. Убедитесь, что она
> экспортирована в `~/.bashrc` до запуска OpenCode — иначе headless-вызовы
> MCP упадут с «no Godot available».

**uv:**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**OpenCode:**

```bash
curl -fsSL https://opencode.ai/install | bash
```

Альтернативные способы: `brew install anomalyco/tap/opencode`, `npm i -g opencode-ai`, `pacman -S opencode`.

**OpenKnowledge:**

```bash
npm install -g @inkeep/open-knowledge
```

Затем выполните `ok init` и `ok start --open` (десктопный `.deb`/`.rpm` — опционально).

**Пути:** `godot-editor-mcp` и `uv` устанавливаются в `~/.local/bin/`, `ok` — туда же; редактор настроек — `~/.bashrc`.

**Диагностика:** чтобы проверить, слушает ли MCP-сервер порт 9080, используйте:

```bash
ss -tlnp | grep 9080
```

### Windows

**Godot.** Загрузите установщик Godot 4.7.2 для Windows и установите его; добавьте путь к `godot.exe` в `PATH` через «Свойства системы → Переменные среды».

**uv** и **OpenCode** — через `scoop`:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
scoop install opencode uv
```

**OpenKnowledge** — установщик с [openknowledge.ai/download](https://openknowledge.ai/download) для Windows 10+ (x64).

> Путь `~\Documents\drowned-lands-the` — пример. Подставьте свой путь к клону репозитория.

**Пути:** `godot-editor-mcp` помещается в `~\scoop\apps\godot-editor-mcp\current\bin`, `ok` — в `~\scoop\apps\opencode\current\bin`; переменные среды задаются через «Свойства системы → Переменные среды».

**Диагностика:**

```powershell
netstat -ano | findstr 9080
```


---

## 8️⃣ Проверка и инициализация

### Шаг 1: Запустите Godot

Откройте проект в редакторе Godot. Убедитесь, что плагин **Godot MCP** включён.

### Шаг 2: Запустите OpenCode

```powershell
cd ~\Documents\drowned-lands-the
opencode
```

### Шаг 3: Проверьте MCP-серверы

**Способ 1 — визуально.** В правой панели OpenCode должно быть:

| Сервер | Статус |
|---|---|
| `godot-mcp` | ✅ Connected |
| `open-knowledge` | ✅ Connected |

**Способ 2 — реальный тест.** Внутри OpenCode введите:

```
Use the godot-mcp toolset to run godot_health_check and show the raw response.
```

Ожидаемый ответ:

```json
{
  "server": "godot-mcp",
  "version": "2026.09.30",
  "transport": "stdio",
  "bridge_url": "ws://localhost:9080",
  "bridge_connected": true
}
```

Если `bridge_connected: false` или ошибка — смотрите раздел «Возможные проблемы».

Дальнейшие шаги инициализации, рабочий процесс и правила работы агентов описаны в [Правилах работы с OpenCode](./opencode-rules.md).

---

## ⚠️ Возможные проблемы

| Проблема | Решение |
|---|---|
| `opencode: command not found` | Перезапустите PowerShell. Проверьте `$PATH`. |
| `godot-editor-mcp: command not found` | Перезапустите PowerShell. Проверьте `uv tool list`. |
| `godot-mcp` не подключается | Откройте Godot, включите плагин. Проверьте `netstat -ano \| findstr 9080`. |
| `npx` не найден | Установите Node.js 24+ с [nodejs.org](https://nodejs.org/). |
| `open-knowledge` не подключается | Запустите OpenKnowledge Desktop. |
| Cline правит игровые файлы | Проверьте `.okignore` в корне проекта. Перезапустите OpenKnowledge. | обе |

### Логи

Linux:

```bash
tail -n 50 ~/.opencode/logs/*.log
ss -tlnp | grep 9080
```

Windows:

```powershell
Get-Content $env:USERPROFILE\.opencode\logs\*.log -Tail 50
netstat -ano | findstr 9080
```

---

## 📌 Чек-лист

- [ ] Git установлен: `git --version`
- [ ] Node.js 24+ установлен: `node --version`
- [ ] Python 3.11+ установлен: `python --version`
- [ ] Godot 4.4+ установлен **[Linux]** / установлен и добавлен в `PATH` **[Windows]**
- [ ] Репозиторий склонирован
- [ ] `uv` установлен: `uv --version`
- [ ] `godot-editor-mcp` установлен
- [ ] Аддон Godot MCP включён в редакторе
- [ ] OpenKnowledge Desktop установлен **[Linux]** / **[Windows]**
- [ ] `opencode.json` содержит обе MCP-секции
- [ ] Оба MCP показывают статус **Connected** в OpenCode
- [ ] Cline отказывается править `project.godot` при тестовом запросе

---

## 🎯 Что вы получите

- **OpenCode** — AI-агент в терминале, работающий с бесплатными моделями.
- **Godot MCP** — мост между агентом и редактором Godot.
- **OpenKnowledge Desktop** — редактор вики с Cline, ограниченным папкой [docs/](./).
- **Git** — полный контроль над версиями.

Если на каком-то шаге возникнут сложности — пришлите вывод команды и скриншот.

---

[Обзор проекта](./index.md) · [Правила вики](./rules.md) · [Правила работы с OpenCode](./opencode-rules.md)
