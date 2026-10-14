---
type: Document
title: Визуальный стиль прототипа
description: "Шрифты, палитра, HUD, карта прототипа — фактические решения main.gd и board.gd."
tags:
  - разработка
  - ui
---

# Визуальный стиль прототипа

Фактические решения UI/карты в `scripts/main.gd` и `scripts/board.gd`.
Шрифты: `assets/fonts/` (Forum — OFL, Inter — OFL). `Cinzel-Variable.ttf` ранее использовался как заголовочный, сейчас не подключён.
---
## 1. Шрифты
| Файл | Роль |
| --- | --- |
| `Forum-Regular.ttf` | Заголовки (старт, финал, модал, меню, управление) |
| `Inter-Variable.ttf` | UI/body: лог, кнопки, caption |
| `Cinzel-Variable.ttf` | **Ранее** использовался как заголовочный; сейчас не подключён |

Загрузка: `_load_fonts()` в `_ready`.  
Применение: `_build_theme()` — `Theme` с типами `Label`/`Button`/`RichTextLabel`. Для `Forum-Regular.ttf` собирается `FontVariation` с `variation_opentype` ("wght": 700) для `font_title`; для `Inter-Variable.ttf` — ("wght": 400/700) для `font_ui`/`font_ui_bold`; `Cinzel-Variable.ttf` не загружается.

**Иконки HUD.** `IconGlyph extends Control` рисует пять векторных глифов в стиле бронзового века: `SAIL` (парус), `OAR` (весло), `HOURGLASS` (час), `IMAGO_MUNDI` (круглая карта мира с Вавилоном в центре), `GRID` (двойная гекс-сетка). Цвет задаётся `set_icon_color()`; для disabled-кнопки глиф сам переключается на `Palette.COL_TEXT_DIM`. Класс подключён в `main.gd._make_icon_button`.

Типичные размеры:
| Элемент | Вариация | Size |
| --- | --- | --- |
| Title старт | `TitleLarge` | 32 |
| Title меню | `TitleLarge` | 32 |
| Title финал | `Title` | 28 |
| Title управление | `Title` | 28 |
| Modal title | `TitleSmall` | 18 |
| HUD year/turn | `HudTitle` / `HudTitleBold` | 16 |
| HUD ship / crew | `Label` / `Bold` | 14 |
| `log_label` | `RichTextLabel` (default) | 14 |
| Modal body | `RichTextLabel` (default) | 14 |
| Modal extra | `CaptionRTL` | 12 |
| Финал: cause | `Label` (default) | 14 |
| Финал: stats | `CaptionRTL` | 12 |
| Кнопки | `Button` / `Secondary` | 14 |
| Меню: подпись `cyberprimitives` | `Caption` | 12 |

Лицензии и upstream — `assets/fonts/README.md`.
---
## 2. Палитра UI
Палитра вынесена в `scripts/palette.gd` (класс `Palette`, `RefCounted`) и используется из `main.gd` / `board.gd` / `menu_background.gd`.
- **Поверхности**: `COL_NIGHT`, `COL_PANEL`, `COL_PANEL_DK`.
- **Рамки**: `COL_BORDER_GOLD`.
- **Текст**: `COL_TEXT`, `COL_TEXT_MID`, `COL_TEXT_DIM`.
- **Вода / структура**: `COL_BLUE`, `COL_BLUE_DK`, `COL_BLUE_LT`, `COL_FLOOD`, `COL_FLOOD_EDGE`, `COL_SEA_VOID`, `COL_SAIL_DK`, `COL_SAIL_LT`.
- **Земля**: `COL_LAND_LOW`, `COL_LAND_EARTH`, `COL_LAND_ROCK`.
- **Электрум-золото**: `COL_GOLD`, `COL_GOLD_LT`, `COL_GOLD_DK`.
- **Гематит-охра**: `COL_OCHRE`, `COL_OCHRE_LT`, `COL_OCHRE_DK`.
- **Малахит**: `COL_MALACHITE`, `COL_MALACHITE_LT`.
- **Лазурит**: `COL_LAPIS`, `COL_LAPIS_LT`.
- **Тиамат-шторм**: `COL_STORM`, `COL_STORM_LT`, `COL_STORM_DK`.
- **Материалы**: `COL_CEDAR`, `COL_CEDAR_DK`, `COL_ACACIA`, `COL_CYPRESS`, `COL_OAK`, `COL_LINEN`, `COL_LINEN_DK`.
- **Оверлеи**: `COL_VEIL`, `COL_SHADOW`.

Смысл:
- **Панели HUD / лог / модал / меню / финал** — тёмная плашка (`COL_PANEL` / `COL_PANEL_DK`) + бронзовая обводка (`COL_BORDER_GOLD`).
- **Акцент** — золото (`COL_GOLD` / `COL_GOLD_LT` / `COL_GOLD_DK`) только на CTA, фрагментах, подсветке башни.
- **Смерть / опасность** — гематит-охра (`COL_OCHRE*`).
- **Фрагменты / ритуал** — лазурит (`COL_LAPIS*`).
- **Команда / успех** — малахит (`COL_MALACHITE*`).
- **Шторм / кольцо бурь** — индиго (`COL_STORM*`).

`COL_BRONZE*`, `COL_PANEL_BORDER`, `COL_PAPYRUS`, `COL_PAPYRUS_TEXT` из старых ревизий в коде отсутствуют — удалены.
---
## 3. Панели и кнопки
Фабрика: `_make_panel_style(bg, border, pad)` → `StyleBoxFlat`  (corner 6, border 1, `content_margin_left/right = pad`, `top/bottom = pad * 0.75`, тень `COL_SHADOW` с alpha 0.45).
| Поверхность | Стиль |
| --- | --- |
| HUD | `COL_PANEL` / `COL_BORDER_GOLD`, pad 14 |
| Лог | `COL_PANEL_DK` / `COL_BORDER_GOLD`, pad 12 |
| Модал | `COL_PANEL` / `COL_BORDER_GOLD`, pad 22, corner 4 |
| Старт | `COL_PANEL` / `COL_BORDER_GOLD`, pad 40 |
| Меню | `COL_PANEL` / `COL_BORDER_GOLD`, pad 36 |
| Управление | `COL_PANEL` / `COL_BORDER_GOLD`, pad 22 |
| Финал | `COL_PANEL` / `COL_BORDER_GOLD`, pad 40 |

Кнопки:
- **Primary** — `bg = COL_GOLD`, `border = COL_GOLD_DK`, текст `COL_NIGHT`.
- **Secondary** — `bg = COL_PANEL_DK`, `border = COL_BORDER_GOLD`, текст `COL_TEXT`, вариация `"Secondary"`.
- **Иконки HUD** — круглые 42×42, `bg = COL_GOLD`, глиф-`IconGlyph` цвета `COL_NIGHT`.

StyleBox создаётся при `_build_*` / `_apply_*_button_style`, **не** в `_refresh_hud`. Строки про `#2a1e10` и `Color(0.85, 0.78, 0.55)` — в коде этих значений нет.
Подпись версии: мелкий Caption (`Inter-Variable.ttf`, 12), цвет `COL_TEXT_DIM`, формат `v0.2.0` — на главном и стартовом экранах (константа версии — в `scripts/`, делает OpenCode).
---
## 4. HUD и лог

- Слева сверху: год · сезон, счётчик хода, пипы фрагментов + `FragCount`, имя корабля, «команда X / Y», полоса команды с засечками `sailReq` (золото) и `req` (лазурит).
- Под панелью HUD — 5 круглых кнопок в ряд: **Парус, Вёсла, Ждать, Центр, Сетка и ветер**. Кнопки «Новая» в HUD нет.
- Лог снизу: `RichTextLabel`, `scroll_following`, цветные префиксы (`season`, `death`, `fragment`, `ship`, `crew`, `storm`).
- Полоса команды: `_refresh_crew_bar()` пересоздаёт засечки `hud_crew_bar_ticks` при каждом обновлении; при полной команде правые углы заливки скругляются.

Новые приватные поля / методы `main.gd`, появившиеся с момента прошлой ревизии (кратко, без кода):

- `_modal_focus_backup: Dictionary` + `_restore_focus_after_modal()` — изоляция Tab-фокуса внутри модалки: при открытии `_show_modal` снимает `focus_mode` с пяти HUD-кнопок и восстанавливает его при закрытии.
- `_confirm_new_game()` — модалка подтверждения по `KEY_N` в запущенной партии.
- `_pip_style_filled` / `_pip_style_empty` — кэш StyleBox пипсов, создаётся в `_ready`, используется в `_refresh_hud`.

---

## 5. Карта (`board.gd`)

| Элемент | Решение |
| --- | --- |
| Виньетка | `_draw_vignette` → 4 × `_vignette_edge` (по 8 сегментов), `draw_polygon` с vertex colors, квадратичное затухание |
| Береговая линия суши | `_draw_land_hex` рисует внешние рёбра гекса только там, где сосед — не суша |
| Кольца Биттер-ривер | `_draw_bitter_river` — три концентрических кольца между `R` и `R_MAP` |
| Башня | `_draw_tower` — 7 тиров лазурита (`COL_LAPIS` → `COL_LAPIS_LT`), медная крыша, пульсирующая звезда на вершине |
| Корпуса кораблей | `_draw_ship_shape` → 4 варианта: `bark` (Улубурун), `depet` (Рекхмир), `keftiu` (Акротири), `gishma` (Язылыкая) |
| Подписи островов | `Inter-Variable.ttf` (вес 600), fallback — `ThemeDB.fallback_font` |

edge-клетки в `_draw_cells` не рисуются (ветка `HexGrid.is_edge` — `continue`); граница мира читается по отсутствию гексов и по маякам. Строку про `beacon_roll > 0.85` удалить: поле осталось в `menu_background.gd._draw_stars`, а не в `board.gd`.

---

## 6. Принципы UI / HUD / UX

1. **Консистентность** — одинаковые компоненты, отступы, цвета и поведение на всех экранах; один источник истины для стиля.
2. **Когерентность** — связность экранов, сценариев, текстов и переходов: каждый переход логичен и предсказуем.
3. **Конгруэнтность** — соответствие жанру, платформе, аудитории и историческим референсам (бронзовый век); дизайн поддерживает сеттинг.
4. **Синергия** — элементы усиливают друг друга; нет визуального и смыслового шума, каждый элемент несёт роль.
5. **Современные стандарты** — доступность, адаптивность, читаемость, иерархия, обратная связь, состояния компонентов, управление фокусом.
6. **Историческая достоверность и сеттинг** — учитывать, но не в ущерб удобству и другим принципам.

Технические правила:

- Один визуальный язык: электрум-золото, гематит-охра, лазурит, тиамат-индиго, морская тьма.
- Шрифты только через `_build_theme()` после `_load_fonts()`.
- Не анимировать UI layout каждый кадр; море/pulse — в `_draw` board.
- Логику хода и reachability не смешивать с StyleBox.

---

## 7. Процедурный фон `menu_background.gd`

Класс `MenuBackground extends Control` — анимированный фон для экранных оверлеев (`start_screen`, `end_screen`, `menu_screen`, `controls_screen`). Рисует то же, что и `board._draw_sea_bg`, плюс опциональные звёзды-маяки.

| Поле | Значение по умолчанию |
| --- | --- |
| `base_color` | `Palette.COL_BLUE` |
| `wave_color` | `Color(Palette.COL_TEXT_MID, 0.10)` |
| `stars_enabled` | `false` |
| `star_count` | `90` |
| `pattern` | `"waves"` (варианты: `stars`, `horizon`, `vortex`, `halo`, `meteors`, `clouds`) |

`mouse_filter = MOUSE_FILTER_IGNORE` — фон не перехватывает клики.

**Сгенерированные наброски арта, музыки и видео хранятся в `drafts/`** (подпапки `drafts/image`, `drafts/audio`, `drafts/video`) в корне репозитория; в Godot import и в релизный билд они не попадают, пока файл явно не перенесён в `assets/`.

---

## 8. Финальный экран — варианты (`_apply_end_visuals`)

`end_screen` использует `MenuBackground` (`end_bg`) и заголовок `end_title`. Набор цветов зависит от причины финала; `end_cause` (14, Label default) и `end_stats` (12, `CaptionRTL`) — общие. `_show_end` собирает строку `Прожито` через `GameState.total_turns`, формат «X лет · Y дней пути».

| `kind` | Заголовок | `modulate` | `base_color` | `pattern` |
| --- | --- | --- | --- | --- |
| `victory` | ВАВИЛОНСКАЯ БАШНЯ | `COL_GOLD` | `COL_LAPIS` | `stars` |
| `edge` | КРАЙ МИРА | `COL_BLUE_LT` | `COL_BLUE_DK` | `horizon` |
| `storm` | БУРЯ ПОГЛОТИЛА | `COL_STORM_LT` | `COL_STORM_DK` | `vortex` |
| `tower` | БАШНЯ НЕ ПУСТИЛА | `COL_STORM_LT` | `COL_NIGHT` | `halo` |
| `crew` | КОМАНДА ПОГИБЛА | `COL_OCHRE_LT` | `COL_OCHRE_DK` | `meteors` |
| _ (default) | КОРАБЛЬ ПОГИБ | `COL_OCHRE_LT` | `COL_OCHRE_DK` | `clouds` |

Условия выбора `kind` — в `prototype-mechanics.md` §6 (таблица «Состояние и победа»).

---
## Связанные документы

- Механика: [Математика и механика](./prototype-mechanics.md)
- Сборка: [Реализованные механики](./implemented-features.md)
- Шрифты upstream: [assets/fonts/README.md](/assets/fonts/README.md)
