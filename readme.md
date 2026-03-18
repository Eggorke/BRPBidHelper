# BRPBidHelper

Разработано для гильдии **BELUGA** на сервере **Nordanaar, Turtle WoW** | Автор: **Eggorkus**
Developed for guild **BELUGA** on **Nordanaar, Turtle WoW** | Author: **Eggorkus**

---

Аддон для помощи в рейдовом распределении лута через DKP-систему. Показывает окно с информацией о выставленном предмете, вашим текущим DKP и кнопками для быстрой ставки или ролла.

## Как работает

Когда мастер лутер анонсирует предмет через raid warning (с ссылкой на предмет), у всех участников рейда автоматически открывается окно аддона. В окне отображается:

- Иконка и название предмета
- Таймер обратного отсчёта
- Имя текущего мастер лутера
- Ваш гильдейский ранг
- Ваш текущий DKP по двум рейдам

Ставка отправляется шёпотом мастер лутеру.

## DKP в офицерских заметках

Аддон читает DKP из офицерской заметки гильдии. Формат заметки:

```
{NAXX:KARA}
```

- **Первая цифра** — DKP за **Naxxramas**
- **Вторая цифра** — DKP за **Karazhan**

Пример: `{450:120}` → 450 NAXX DKP, 120 KARA DKP.

Всё что написано в заметке вне фигурных скобок — игнорируется и может использоваться для других пометок.

## Кнопки

| Кнопка | Действие |
|---|---|
| **Bid** | Отправить ставку из поля ввода шёпотом мастер лутеру |
| **ALL IN NAXX** | Поставить весь NAXX DKP (с подтверждением) |
| **ALL IN KARA** | Поставить весь KARA DKP (с подтверждением) |
| **Roll MS** | Бросить кубик `/roll 1-100` — Main Spec |
| **Roll OS** | Бросить кубик `/roll 1-99` — Off Spec |
| **Roll TMOG** | Бросить кубик `/roll 0-98` — Transmog |

## Требования

- Лут-метод должен быть **Master Loot**
- DKP должен быть прописан в офицерских заметках в формате `{NAXX:KARA}`
- Для чтения офицерских заметок нужен доступ к ним

## Настройка меток рейдов

Если в вашей гильдии рейды называются иначе, поправьте две строки в начале файла `BRPBidHelper.lua`:

```lua
local RAID1_LABEL = "NAXX"   -- первая цифра в заметке {RAID1:RAID2}
local RAID2_LABEL = "KARA"   -- вторая цифра в заметке {RAID1:RAID2}
```

Например, для MC и BWL:
```lua
local RAID1_LABEL = "MC"
local RAID2_LABEL = "BWL"
```

После смены меток — перезагрузить UI (`/reload`). Названия автоматически обновятся на кнопках и в отображении DKP.

## Настройки (SavedVariables)

- `FrameShownDuration` — сколько секунд показывать окно (по умолчанию 30)
- `FrameAutoClose` — автоматически закрывать окно по истечении таймера (по умолчанию включено; у мастер лутера окно не закрывается автоматически)

---

# BRPBidHelper (English)

An addon to assist with raid loot distribution using a DKP system. Displays a window with item information, your current DKP, and buttons for quick bidding or rolling.

## How it works

When the master looter announces an item via raid warning (containing an item link), the addon window automatically opens for all raid members. The window shows:

- Item icon and name
- Countdown timer
- Current master looter's name
- Your guild rank
- Your current DKP for both raids

Bids are sent as a whisper to the master looter.

## DKP in officer notes

The addon reads DKP values from guild officer notes. The required format is:

```
{NAXX:KARA}
```

- **First number** — DKP for **Naxxramas**
- **Second number** — DKP for **Karazhan**

Example: `{450:120}` → 450 NAXX DKP, 120 KARA DKP.

Any text outside the curly braces is ignored and can be used freely for other notes.

## Buttons

| Button | Action |
|---|---|
| **Bid** | Send the typed amount as a whisper to the master looter |
| **ALL IN NAXX** | Bid all NAXX DKP (requires confirmation) |
| **ALL IN KARA** | Bid all KARA DKP (requires confirmation) |
| **Roll MS** | Roll `/roll 1-100` — Main Spec |
| **Roll OS** | Roll `/roll 1-99` — Off Spec |
| **Roll TMOG** | Roll `/roll 0-98` — Transmog |

## Requirements

- Loot method must be set to **Master Loot**
- DKP must be stored in officer notes in the format `{NAXX:KARA}`

## Saved Variables

- `FrameShownDuration` — how many seconds to display the window (default: 30)
- `FrameAutoClose` — automatically close the window when the timer expires (default: true; the master looter's window never closes automatically)
