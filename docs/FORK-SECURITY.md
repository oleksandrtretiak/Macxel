# Безпека форку

Macxel — особиста збірка Vorssaint з посиленою безпекою. Тут описано, що
знайшов аудит коду upstream, що змінено і як повернути вимкнене. Аудит
проведено на версії 3.4.1-beta.1 (2026-10-04), зміни перенесено й перевірено
заново на версії 3.4.5 (2026-11-25).

Усі зміни в коді позначені коментарем `FORK-SECURITY`:

```bash
grep -rn "FORK-SECURITY" Sources Tools build.sh .github
```

## Загальний висновок аудиту

Шкідливого коду, бекдорів, прихованої телеметрії, бінарників чи сторонніх
залежностей немає. Віддаленої (мережевої) атаки на застосунок не знайдено.
Знахідки локальні: майже всі вимагають, щоб на Mac уже працювала шкідлива
програма від імені користувача.

| Рівень | Кількість | Стан у Macxel |
|---|---|---|
| 🟠 High | 1 | вимкнено + виправлено |
| 🟡 Medium | 4 | вимкнено або виправлено (1 виправив upstream) |
| 🔵 Low | 7 | 5 виправлено, 1 виправив upstream, 1 лишився |
| ⚪ Info / документація | 7 | 4 виправлено |

## Перемикачі

`Sources/Vorssaint/Core/ForkSecurity.swift` — код механізмів лишився на місці,
вимкнено лише точки входу. Щоб повернути механізм, змініть значення на `true`.

| Перемикач | Значення | Чому вимкнено |
|---|---|---|
| `selfUpdateEnabled` | `false` | Оновлення тягнуться з upstream-репозиторію й перевіряються під Team ID автора: форк або не оновиться, або замінить себе офіційною збіркою. Тут же була знахідка High (нижче). |
| `fanControlEnabled` | `false` | Root-демон вентиляторів довіряє лише підпису автора, тож у форку не запрацює; і це найпривілейованіший компонент застосунку. Читання обертів вентиляторів працює й без нього. |
| `agentCLIProbesEnabled` | `false` | Картки лімітів Codex і Claude Code запускали `codex` / `claude` з `~/.local/bin`, `PATH`, менеджерів версій або будь-якого бандла з ID Codex без перевірки підпису; процес успадковував дозволи застосунку (Accessibility, Screen Recording…). |
| `cloudSharingEnabled` | `false` | Тимчасові посилання на знімки й записи та відгуки з застосунку йдуть на `screenshots.vorssaint.com` — сервер автора upstream. Форк не має надсилати туди ваші знімки чи звіти. |

> Якщо колись увімкнете `selfUpdateEnabled`, спершу замініть репозиторій
> (`UpdateService.repository`) і Team ID (`UpdateInstallerSupport`,
> `FanControlXPC.teamID`) на власні.

## Виправлення

| # | Рівень | Проблема | Виправлення | Файл |
|---|---|---|---|---|
| 1 | 🟠 | Інсталер оновлень з правами root перевіряв підпис DMG і окремо монтував той самий файл із `$TMPDIR` користувача — файл можна було підмінити між кроками. Шлях з правами root також можна було примусово ввімкнути через `defaults write`. | root копіює DMG у приватну теку `/private/var/root/…` і перевіряє та монтує лише копію (`-readonly`); вибір шляху з правами root — тільки за реальним правом запису в теку застосунку | `Update/UpdateInstallerSupport.swift`, `Update/UpdateService.swift` |
| 2 | 🟡 | Запуск `codex` і `claude` без перевірки підпису | вимкнено перемикачем | `AgentUsage/AgentCodexResetService.swift`, `CodexProfileLimitsService.swift`, `AgentUsageService.swift` |
| 3 | 🟡 | `perl` для Now Playing успадковував `PERL5OPT`/`PERL5LIB` | чисте оточення (`PATH` лише системний) | `Notch/NotchMusicService.swift`, `RadialMenu/RadialNowPlayingService.swift` |
| 4 | 🟡 | Імпорт чужого файлу налаштувань міг створити ярлик Command Bar, що запускає програму | при імпорті ярлики-скрипти відкидаються | `Core/SettingsBackupSupport.swift` |
| 5 | 🟡 | Історія буфера обміну пропускала лише `ConcealedType` | ✅ виправив upstream (`isTransient`) | — |
| 6 | 🔵 | Ім'я файлу з переносом рядка ставало двома шляхами у Finder cut/paste | такий вибір відхиляється, розділювач — лише `\n` | `Finder/FinderCutPaste.swift` |
| 7 | 🔵 | Команда з правами root (через `perl`) успадковувала оточення | `env -i` з системним `PATH` | `DetachedProcess.swift` |
| 8 | 🔵 | Інсталер міг запустити `open` від root | `open` лише від імені користувача | `Update/UpdateInstallerSupport.swift` |
| 9 | 🔵 | URL завантаження оновлення не був обмежений | лише `https://github.com` | `Update/UpdateServiceSupport.swift` |
| 10 | 🔵 | Інсталер DMG знімав карантин і приймав застосунок без перевірки, якщо Gatekeeper вимкнено | без перевірки `spctl` застосунок не встановлюється | `DiskImageInstaller/DiskImageInstallerService.swift` |
| 11 | 🔵 | Бекап налаштувань (з текстами сніпетів) мав права 0644 | ✅ виправив upstream (0600) | — |
| 12 | 🔵 | Тимчасові вставки записувались чужими менеджерами буфера | позначка `TransientType` | `TransientPaste.swift` |
| 13 | ⚪ | Нерозпізнана поточна версія вважалась старішою | тепер ні | `Update/UpdateServiceSupport.swift` |
| 14 | ⚪ | sudoers-правило записувалось до перевірки `visudo` | перевірка тимчасового файлу, потім `mv` | `ShellSupport.swift` |
| 15 | ⚪ | `LatestScreenshot.png` мав права 0644 | 0600 | `QuickTools/ScreenshotService.swift` |
| 16 | ⚪ | `PERMISSIONS.md` не згадував функції, що читають клавіатуру | додано розділ | `docs/PERMISSIONS.md` |

## Ребрендинг

`TRADEMARKS.md` upstream вимагає, щоб форк мав іншу назву, іконку, bundle ID і
підпис. Тому:

- назва застосунку — **Macxel** у всьому інтерфейсі (15 мов, з виправленням
  відмінків у словацькій, турецькій і корейській), в Info.plist, `build.sh`,
  `Tools/`, CI і документації;
- bundle ID — `com.oleksandrtretiak.macxel` (`.dev` для `--dev`);
- файл конфігурації — `~/.config/macxel/settings.plist`, щоб не ділити його з
  офіційним Vorssaint;
- нова іконка: піксельна «M» (`Resources/Brand/`);
- sudoers-правило — `/etc/sudoers.d/macxel-clamshell`; правила офіційного
  застосунку форк більше не видаляє, як і його старі бандли під час `--install`;
- розділи «Підтримка» і «Спільнота» (Buy Me a Coffee, Discord, X, Homebrew,
  зірочка на GitHub) ведуть на проєкт Vorssaint і так і підписані;
  «View on GitHub» веде на форк;
- копірайт `© 2026 Vorssaint` і заголовки ліцензії збережено, як вимагає GPL;
- внутрішні назви (`Sources/Vorssaint`, типи й ключі налаштувань `Vorssaint*`)
  не змінено — так простіше переносити зміни з upstream.

## Свідомо не змінено

- **Історія буфера обміну не очищається автоматично за часом і потрапляє в
  Time Machine.** Це поведінка, а не вразливість: файл має права 0600, сама
  історія вимкнена за замовчуванням.
- **Root-демон вентиляторів не перевіряє мінімальну версію клієнта.** Він
  вимкнений, а прийняті команди й так обмежені 0–100 %.

## CI форку

- `ci.yml` отримав `workflow_dispatch`, щоб збірку й тести можна було
  запустити вручну на будь-якій гілці.
- Боти `issue-fix-status.yml` працюють лише в `vorssaint/vorssaint-utils`.
- `release.yml` і так обмежений upstream-репозиторієм.

## Збірка для себе

```bash
./build.sh --install         # «Macxel», bundle id com.oleksandrtretiak.macxel
./build.sh --dev --install   # «Macxel (Developer)», без оптимізацій
./build.sh --test            # юніт-тести
```

Обидві збірки мають власний bundle ID і не конфліктують з офіційним
Vorssaint. Без Apple Developer ID `build.sh` сам створює локальний
самопідписаний сертифікат (`Tools/setup-signing.sh`).
