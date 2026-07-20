# Enemy Highlight

Плагин для The Lord of the Rings Online, который позволит вручную назначать
другим игрокам статусы `Friend`, `Neutral` и `Enemy`, а затем показывать статус
текущей выбранной цели.

Проект пока находится на стадии технического прототипа. Текущая версия только
проверяет доступ к выбранной цели через LOTRO Lua API. Управление списками и
цветной индикатор ещё не реализованы.

## Установка прототипа

1. Скопировать каталог `HighlightPlayers` целиком в:
   `Documents\The Lord of the Rings Online\Plugins`.
2. Итоговый путь к манифесту должен быть:
   `Documents\The Lord of the Rings Online\Plugins\HighlightPlayers\HighlightPlayers.plugin`.
3. Войти персонажем в игру.
4. Обновить список плагинов командой `/plugins refresh`.
5. Открыть менеджер плагинов LOTRO и загрузить `Enemy Highlight`.

После успешной загрузки в чате появится сообщение:

```text
[HighlightPlayers] Local player: <name> | side=<FreePeople|MonsterPlayer> | alignment=<value>
[HighlightPlayers] Enemy Highlight v0.1.0 loaded (target prototype). Select a target or use /eh probe.
```

## Проверка выбранной цели

Плагин автоматически пишет диагностическую строку при каждой смене цели.
Повторно вывести сведения о текущей цели можно командой:

```text
/eh probe
```

Пошаговый сценарий проверки находится в
[`docs/prototype-test.md`](docs/prototype-test.md).

## Текущие команды

- `/eh` — вывести сведения о текущей цели;
- `/eh probe` — вывести сведения о текущей цели;
- `/eh help` — вывести справку прототипа.

Команды MVP, описанные в ТЗ, будут добавлены после подтверждения прототипа.

## Документация

- [Техническое задание](docs/requirements.md)
- [Проверка прототипа в LOTRO](docs/prototype-test.md)
