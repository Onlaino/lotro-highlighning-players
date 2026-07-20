# Выпуск релиза Enemy Highlight

**Русский** | [English](releasing.en.md)

Релизы создаются автоматически через GitHub Actions. Workflow находится в
`.github/workflows/release.yml` и запускается после отправки тега вида `v*`,
например `v0.1.0`.

## 1. Модель веток

- `staging` — разработка и проверка изменений;
- `main` — стабильное состояние, из которого создаются релизы.

Обычные изменения сначала коммитятся в `staging`. После ручной проверки в
LOTRO они переносятся в `main`. Релизный тег создаётся только на нужном коммите
ветки `main`.

## 2. Первоначальная настройка GitHub

В интерфейсе репозитория необходимо один раз:

1. Назначить `main` веткой по умолчанию в настройках репозитория.
2. Открыть `Settings -> Actions -> General`.
3. Убедиться, что GitHub Actions разрешены для репозитория.
4. В разделе `Workflow permissions` разрешить `Read and write permissions` и
   сохранить настройку.

Workflow дополнительно ограничивает выданные права значением
`contents: write`. Оно необходимо для создания GitHub Release и прикрепления
архива.

## 3. Подготовка версии

Перед релизом:

1. Завершить изменения в `staging`.
2. Проверить плагин внутри клиента LOTRO по `docs/manual-test.md`.
3. Изменить `<Version>` в
   `HighlightPlayers/HighlightPlayers.plugin` на новую версию без префикса
   `v`, например `0.1.0`.
4. При необходимости обновить README и заметки о важных изменениях.
5. Закоммитить и отправить `staging`.

Пример:

```powershell
git switch staging
git add -- HighlightPlayers README.md docs
git commit -m "chore: prepare v0.1.0 release"
git push upstream staging
```

## 4. Перенос стабильной версии в main

Если `main` не содержит собственных изменений и допускается fast-forward:

```powershell
git switch main
git pull --ff-only upstream main
git merge --ff-only staging
git push upstream main
```

Если Git сообщает о расхождении веток, релиз останавливается. Изменения нужно
сначала проверить и объединить через Pull Request `staging -> main`, не
применяя принудительный push.

После публикации `main` рекомендуется вернуть рабочую копию на ветку
разработки:

```powershell
git switch staging
```

## 5. Создание релизного тега

Версия тега обязана совпадать с версией манифеста:

```text
тег:                v0.1.0
версия манифеста:    0.1.0
```

Создать тег на актуальном `main`:

```powershell
git switch main
git pull --ff-only upstream main
git tag -a v0.1.0 -m "Enemy Highlight v0.1.0"
git push upstream v0.1.0
git switch staging
```

Отправка тега запускает workflow `Create release` во вкладке `Actions`.

## 6. Что делает workflow

Workflow:

1. загружает исходники именно помеченного тегом коммита;
2. проверяет совпадение версии тега и `<Version>` в манифесте;
3. создаёт архив `Enemy-Highlight-v0.1.0.zip`;
4. создаёт файл контрольной суммы
   `Enemy-Highlight-v0.1.0.zip.sha256`;
5. создаёт GitHub Release и автоматически формирует release notes;
6. прикрепляет ZIP и SHA-256 к релизу.

Внутри установочного архива каталог `HighlightPlayers` находится на верхнем
уровне:

```text
Enemy-Highlight-v0.1.0.zip
└── HighlightPlayers
    ├── HighlightPlayers.plugin
    ├── Main.lua
    └── остальные Lua-файлы
```

Пользователям нужно скачивать этот ZIP из блока `Assets`, а не автоматически
созданный GitHub архив `Source code.zip`.

## 7. Проверка опубликованного релиза

После завершения workflow:

1. Открыть вкладку `Actions` и убедиться, что запуск зелёный.
2. Открыть раздел `Releases` и проверить название и тег.
3. Скачать прикреплённый ZIP.
4. Убедиться, что внутри него сразу находится каталог `HighlightPlayers`.
5. Установить архив в чистый каталог LOTRO Plugins и выполнить короткую
   проверку загрузки, `/eh`, добавления записи и индикатора цели.

## 8. Типовые ошибки

### Tag and manifest versions do not match

Тег и `<Version>` отличаются. Необходимо исправить версию в манифесте,
перенести исправление в `main` и выпустить новый корректный тег.

### Resource not accessible by integration

Workflow не получил право создать релиз. Проверить `Settings -> Actions ->
General -> Workflow permissions` и значение `contents: write` в workflow.

### Workflow не запустился

Проверить, что:

- тег отправлен в GitHub, а не существует только локально;
- имя тега начинается с `v`;
- `.github/workflows/release.yml` присутствует в коммите, на который указывает
  тег;
- Actions разрешены в настройках репозитория.

### Релиз опубликован, но ZIP отсутствует

Открыть конкретный запуск во вкладке `Actions` и проверить шаги
`Build installation archive` и `Create GitHub release`.
