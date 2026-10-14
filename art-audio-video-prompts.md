---
type: Document
title: Промпты арта, аудио и видео
description: "Канон визуала и звука, референсы бронзового века, базовые промпты; артефакты в drafts/."
tags: [разработка, арт, аудио, видео, промпты]
---

# Промпты арта, аудио и видео

Канон визуала и звука игры *The Drowned Lands*: референсы бронзового века, базовые промпты для генерации арта, музыки и видео. Все сгенерированные артефакты хранятся в `drafts/`.

## Политика `drafts/`

Сгенерированные наброски арта, музыки и видео хранятся в подпапках корня:

- `drafts/image` — референсы и наброски арта;
- `drafts/audio` — наброски музыки и звуковых эффектов;
- `drafts/video` — наброски видео (обзорные ролики, геймплей-монстрации).

Артефакты **не импортируются в Godot** и **не попадают в релизный билд**, пока файл явно не перенесён в `assets/`. `drafts/` помечен `.gdignore`, поэтому Godot его игнорирует.

## Визуальный канон

Базируется на палитре `scripts/palette.gd` и решениях [Визуального стиля](./ui-style.md):

| Цвет | Назначение |
| --- | --- |
| Egyptian blue (CaCuSi4O10) | вода, небо, структура, информация |
| Electrum gold (ἤλεκτρον) | акцент, CTA, фрагменты, башня |
| Hematite ochre (Fe₂O₃) | опасность, смерть, ранение |
| Lapis lazuli (Na₈₋₁₀(Al₆Si₆O₂₄)S₂₋₄) | ритуал, боги, артефакты, Вавилон |
| Tiamat indigo | кольцо бурь, хаос, потоп |
| Malachite (Cu₂CO₃(OH)₂) | команда, успех, жизнь |

**Стиль — фреска бронзового века, а не высокое фэнтези:** земляные и охра́ные тона земли, деревянный корпус корабля, льняные паруса, каменная архитектура, папирусные свиты. Никаких средневековых каравелл, готических шпилей, огнестрельного оружия, современных объектов и киберпанка. Греческие, готические, скандинавские и другие пост-бронзововековые мотивы не допускаются.

## Изображения и референсы

**Археология и искусство:**

- Фреска «Флотиллия» из Акротири (Санторини) — парусные суда бронзового века;
- Фрески Кноссоса — минойские корабли, порты;
- Рельефы Рекомхира (Рехмире), гробница в Фивах — египетские корабли, груз, флот;
- Корабль Улубурун (Uluburun shipwreck) — грузовое судно позднего бронзового века, груз;
- Рельефы Йашылкая (Yazılıkaya) — процессия богов, церемониальные ладьи;
- Imago Mundi (Вавилонская мировая карта) — круглый мир с «горькой рекой» и Вавилоном в центре;
- Палетта Нармера, египетские ладьи фараонов;
- Реставрационные раскраски: Egyptian blue, orpiment (орпигмент), hematite, malachite, lapis lazuli.

**Избегать:** средневековых каравелл/галиотов, парусной эпохи (XV–XIX вв.), готики, скандинавских драккаров, рыцарства, современных судов, самолётов, автомобилей, пластика/светодиодов.

## Музыка и референсы

**Звуковая эстетика:** камерная, древневосточная инструментальная музыка бронзового века. Инструменты: лира (кифара), авлос/флейта, медные гонги и литавры, перкуссия, арфы; минималистичная аранжировка, много «воздуха», без эпических оркестровых фанфар и хоралов. Никакой современной электроники, рока, джаза и голливудских «epic trailer brass».

**Референсы:**

- Michael Levy — *Echoes of Ancient Mesopotamia*, *Echoes of Ancient Canaan*;
- Petros Tabouris — *Minoan Crete* (Crete of the Minos), *Atlantis — Ship of the Lost Civilization*;
- Giles Lewin — *Ancient Civilizations* library (Ancient Egypt, Ancient Greece);
- Эпическая античная/ближневосточная музыка для документального кино.

## Промпты для арта

### Меню / главный экран

> Epic bronze-age sea fresco style, The Drowned Lands main menu — a vast flat world under a domed night sky, a lone ancient cedar ship sailing on deep Egyptian-blue water, the Tower of Babylon glowing in the center surrounded by a ring of storm, ancient map fragments floating, electrum gold borders, lapis lazuli accents, fresco texture, no medieval caravels, no modern objects, no fantasy.

### Остров / высадка

> Ancient Near East bronze-age landscape fresco, a lone desert island rising from the drowned world, palm trees, ruins of a fallen city half-submerged, warm ochre earth and limestone rock, Egyptian blue sea, electrum gold sunlight, fresco texture, Akrotiri-style, no medieval, no modern, no fantasy castles.

### Штормовое кольцо

> Mythic storm ring around the Tower of Babylon, Tiamat indigo swirling vortex, ancient Mesopotamian chaos, lightning over the drowned flat world, fresco and bas-relief style, heavy atmospheric haze, electrum-gold beacon at center, no modern technology, no fantasy magic runes.

### Парус / гребля

> Bronze-age sailboat moving under sail with ancient Egyptian blue waves, linen square sail, cedar hull, oars rowing in calm wind, fresco style, Akrotiri flotilla inspiration, warm gold light, no medieval caravel, no modern objects.

### Победа / конец экипажа

> Victory: Tower of Babylon reached, four map fragments glowing in electrum gold, lapis lazuli night sky, triumph fresco, golden light; Crew end: the old ship lost at sea, hematite-ochre danger tones, waves swallowing the vessel, ancient Near East fresco style, no fantasy, no modern.

## Промпты для аудио

**Меню (бесшовный луп, 15–30 с):**

> ancient lyre and soft aulos ambient, calm bronze-age sea, minimal and meditative, desert winds, distant water sounds, 15–30 seconds seamless loop, no modern instruments, no epic brass, Michael Levy / Petros Tabouris style.

**Игровая сессия / плавание:**

> sparse lyre arpeggios over deep water ambience, gentle wind and oars rowing rhythm, ancient Egypt/Minoan Crete atmosphere, cinematic but quiet, seamless 20-second loop, no choir, no trailer drums.

**Шторм:**

> deep bronze gong and timpani, rising aulos dissonance, thunder over the sea, storm ring vortex, ominous and heavy, 15–30 s seamless loop, no rock or electronic elements.

**Победа / конец:**

> Victory — ascending lyre and aulos in warm major key, electrum-gold resolution, 20 s seamless loop; Crew end — melancholic aulos solo over dark water ambience, hematite-ochre mood, no modern instruments.

## Промпты для видео

**Обзор геймплея (30–60 с, без озвучки):**

> cinematic montage of the drowned bronze-age world: hex map zooming into the sea, an ancient ship sailing toward the storm ring, islands resurfacing and sinking with seasons, crew rowing and setting sail, close-ups of fresco-style UI and vector icons, electrum gold and lapis lazuli color grading, no modern objects, no UI watermark.

**Геймплейный слайд-ролик (15–30 с, бесшовный луп):**

> continuous loop of sailing along the horizon at dusk, storm ring faintly visible in the distance, calm rowing scenes alternating with sail under wind, ancient ship model, sea waves, fresco color palette, seamless 30 s loop.

---

[Разработка](./development.md) · [Обзор проекта](./index.md)