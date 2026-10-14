---
type: Document
title: Математика и механика прототипа
description: "Как устроено в коде: сетка, ветер, reachability, ход, победа, корабли."
tags:
  - разработка
  - механика
---

# Математика и механика прототипа

Документ фиксирует **как устроено в коде** (Godot 4.7.2), а не целевой дизайн «на вырост».
Источники: `scripts/hex_grid.gd`, `wind.gd`, `reachability.gd`, `turn.gd`, `actions.gd`, `island_actions.gd`, `balance.gd`, `game_state.gd`.
---
## 1. Шестиугольная сетка
- Ориентация: **pointy-top**.
- Координаты: axial `(q, r)`; расстояние — кубическая метрика через `HexGrid.distance`.
- Перевод в пиксели: `HexGrid.hex_to_pixel` / `pixel_to_hex` с `Balance.HEX_SIZE`.
- Особые клетки:
  - **Шторм** — кольцо вокруг центра (`HexGrid.is_storm`).
  - **Башня** — клетка `(0, 0)` (`HexGrid.is_tower`).
- Параметры генерации: `R = 13` (игровой радиус), `R_MAP = 16` (радиус карты), `R_MARGIN = 2`;
  `HEX_SIZE = 26.0`; `ISLAND_COUNT = 22`; `STORM_INNER = 1`, `STORM_OUTER = 2`.

### Генерация островов (`MapGenerator`)
- Карта состоит из `R_MAP`-радиуса гексов, островные клетки отбираются с отступом `R_MARGIN` от игрового радиуса.
- Высота острова: `2 + randi() % 19` — диапазон **2–20 локтей**.
- С шансом **55%** рядом с островом создаётся соседний остров высотой `max(2, h - 3 - randi() % 5)`.
- Фрагменты карты ставятся на **4 островах** с `height >= 8` (если таких меньше 4 — берутся все острова).
- Стартовая клетка: до 300 попыток; состав команды при старте `sailReq + randi() % (crewMax - sailReq + 1)`.

Камера: смещение `board.camera_offset` + `Balance.MAP_OFFSET_Y`; pan WASD / RMB / MMB, clamp `Balance.PAN_LIMIT`.
---
## 2. Ветер
«Дыхание мира» — радиальное поле от центра карты.
- `Wind.wind_at(q, r, season_index, variable_offset)` → `{ angle, strength }`.
- Направление и сила зависят от **сезона** (`Balance.SEASONS`: имя, turns, wind mode, множители смертности и т.д.).
- В режиме **переменного** ветра используется `state.variable_offset` (меняется на границе сезона в `Turn`).
- MP под парусом вычисляются в единой точке: `Balance.sail_mp(ship_def, crew, strength)` — `sail · min(1, crew/sailReq) · strength`.
Курсовой угол относительно ветра:
```text
a = min(deg, 360 - deg)   # отклонение 0…180
```

| a (°) | Курс (код) | Flavor-ключ | Модификатор (COURSE_MOD) |
| --- | --- | --- | --- |
| ≤ 30 | попутный | `sailFair` | 1.0 |
| ≤ 90 | косой | `sailClose` | 0.8 |
| ≤ 150 | боковой | `sailBeam` | 0.45 |
| > 150 | против ветра | — | 0.0 (движение под парусом недоступно) |

При `a > 150` возвращается `unreachable` или `calm`; отдельного flavor-ключа для противного ветра нет.
## 3. Достижимость (Reachability)
Reachability.refresh(state) заполняет:
state.reachable — массив словарей клеток с полями вроде q, r, mp, deg, d, cm, storm;
state.landable — Array Vector2i соседних островов, на которые можно высадиться в текущем режиме.
Парус (mode == "sail")
Базовый запас хода зависит от силы ветра и курсового модификатора. `Reachability` собирает `reachable[]` inline (для скорости — `sail_base · cm · w_strength`); `Actions.try_move` для проверки непустого бюджета дёргает `Balance.sail_mp` (§2). `Actions` использует `Balance.sail_mp` как единую точку правды; `Reachability` считает inline для скорости — при изменении формулы править обе ветки.
Клетка достижима, если накопленный cost ≤ доступных MP и в пределах MAX_RANGE (в коде — 8).
Штормовые клетки помечаются; заход без всех фрагментов = поражение (обрабатывается в Actions.try_move).
Вёсла (`mode == "row"`) — MP от доли команды относительно требования `req` корабля (`req` / crew).
Actions.try_move передаёт корабль, команду и силу ветра в `Balance.sail_mp` — единая точка расчёта MP под парусом.
Курсовой угол для гребного режима не режет доступ так же, как под парусом.
Высадка
Остров с height > water_level, соседний и попавший в landable.
В Actions.try_move проверка: c.x == q and c.y == r по state.landable (не Dictionary).
## 4. Ход и сезон (Turn)
Turn.end_turn(state) → массив событий для лога:
- В самом начале `end_turn`, после проверки `game_over`, инкрементируется `state.total_turns += 1` — общий счётчик «дней пути» для финального экрана.
- Инкремент season_turn; при исчерпании хода сезона — смена сезона / года.
- Уровень воды — ступенчатый пересчёт по вики (flood.md, «Ускорение по годам»): годы 1–4 → +1 локтя/год, 5–8 → +2, 9+ → +3. Реализовано через year_bonus в _apply_season_end (bonus 0 / 1 / 2 при year >= 5 / 9).
- Затопление — острова с height <= water_level → flooded.
- Смертность — базово 0.012 на ход с сезонным множителем; команда может дойти до 0.
- При crew <= 0 → game_over, событие с end: "crew" и текстом из Flavor.END_CREW.
- В самом конце, после `_daily_mortality`, если `state.ship["mode"] == "sail"` и `Wind.wind_at(...)["strength"] < 0.03` — режим принудительно переключается в `"row"` с событием из `Flavor.FLAVOR["calmSwitch"]`.
## 5. Действия
Движение — Actions.try_move
Нет старта / game_over → пустой результат.
Незатопленный остров:
не в landable → tooFar или пусто;
в landable → island_action (без смены клетки корабля до резолва острова).
Иначе — поиск в reachable; нет клетки → calm / unreachable / tooFarRow.
- Успех: обновление q,r,heading → проверка шторм/башня → flavor курса → Turn.end_turn.
  - Под парусом: `"{flavor} {d} гекс. · {course}"` — без MP.
  - На вёслах: `"{flavor} {d} гекс. (гребцы {crew}/{req})"` — без MP.
Ожидание — Actions.wait_day
Flavor «ждать» + Turn.end_turn.
Остров — `IslandActions.explore_island` — обёртка над `_explore_island_impl`:

| Остров | `spend_turn` | `end_turn` | Результат |
| --- | --- | --- | --- |
| Не найден | false | нет | пусто |
| Flooded | false | нет | пусто |
| Обычный | true | да | фрагмент / корабль / экипаж / прочее |

После end_turn при game_over пробрасывается end / end_text в результат.
Смена корабля — swap_ship (отдельный поток модалки).
Внутренняя MP-формула `Balance.sail_mp(...)` остаётся — нужна для расчёта достижимости, но в лог не пишется.

## 6. Состояние и победа
GameState (autoload):
ship, cells, islands, reachable, landable, сезон/год, water_level, fragments, deaths, total_turns, флаги started / game_over.
Старт генерации: только по кнопке «Отчалить» (_on_start_pressed), не в _ready.
В `start_new_game` есть guard `if cells.is_empty(): return`; в `MapGenerator.generate_islands` — guard `if pool.is_empty(): return islands`.
| Состояние | Условие | Результат |
| --- | --- | --- |
| Победа | 4 фрагмента + заход на башню | victory |
| Поражение | Шторм или башня без всех фрагментов | storm / tower |
| Поражение | Команда ≤ 0 | crew |
Balance.FRAGMENTS_NEEDED = 4.

## 7. Корабли (Balance.SHIPS)

| id | name | sail | row | sailReq | req | crewMax | size | hull |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `bark` | Бар | 2 | 2 | 1 | 2 | 5 | 0.92 | bark |
| `depet` | Депет | 4 | 3 | 5 | 6 | 12 | 1.00 | depet |
| `keftiu` | Кефтиу | 6 | 4 | 12 | 14 | 24 | 1.06 | keftiu |
| `gishma` | Гишма | 7 | 5 | 24 | 28 | 40 | 1.14 | gishma |

Поля: id, name, sail, row, sailReq (мин. для режима), req (общее требование), crewMax (предел экипажа), size (визуальный размер), hull (тип корпуса).
Поле crewMin удалено; порог экипажа берётся из sailReq при старте.

Единая формула MP под парусом — `Balance.sail_mp(ship_def: Dictionary, crew: int, strength: float) -> float` (результат `sail · min(1, crew/sailReq) · strength`); используется в `Reachability.refresh` и `Actions.try_move`.

---

### Связанные документы

- Дизайн ветра/потопа/островов: wind.md, flood.md, islands.md
- Что уже в билде: implemented-features.md
- Визуал: ui-style.md
