# RecruitRelay: Guild Recruitment

<p align="center">
  <img src="assets/RecruitRelay-logo.png" alt="RecruitRelay logo" width="256">
</p>

[![GitHub release](https://img.shields.io/github/v/release/Frzok/RecruitRelay-Guild-Recruitment?display_name=tag)](https://github.com/Frzok/RecruitRelay-Guild-Recruitment/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

RecruitRelay is a standalone World of Warcraft Retail addon for composing and
safely posting guild recruitment messages.

It is an original implementation and does not contain code from Guild
Recruitment Helper or any other recruitment addon.

## Features

- Clickable Guild Finder application links.
- Live preview and a per-line 255-byte limit check.
- General, Trade, and Looking For Group channel selection.
- Configurable reminder interval from 5 to 60 minutes.
- Channel rotation when more than one channel is selected.
- Automatic pauses in combat, instances, raids, and while AFK.
- A visible hardware-action button when a message is due.
- Russian and English interfaces.
- No external addon dependencies.
- A reusable guild profile for schedules, progress, contacts, links, and rules.
- Visual recruitment selectors for days, roles, classes, and activities.
- Automatic guild roster counters.

## Message tokens

| Token | Replacement |
| --- | --- |
| `$gname` | Current guild name |
| `$glink` | Clickable Guild Finder link, or guild name as a fallback |
| `$realm` | Current realm |
| `$faction` | Player faction |
| `$player` | Current character name |
| `$online` / `$members` | Online and total guild members |
| `$time` / `$date` | Current local time and date |
| `$raidtime` / `$schedule` | Manual raid time or generated schedule |
| `$days` / `$starttime` / `$endtime` | Individual schedule values |
| `$progress` | Guild progress |
| `$requirements` | Recruitment requirements |
| `$contact` / `$backupcontacts` / `$contacts` | Recruiter contacts |
| `$discord` / `$website` / `$voice` | Community links and voice chat |
| `$language` / `$timezone` / `$region` | Guild location information |
| `$focus` / `$activities` | Guild focus and selected activities |
| `$needs` / `$roles` / `$classes` | Generated recruitment needs |
| `$priority` | Priority recruits |
| `$age` / `$loot` / `$about` | Other guild profile information |

The guild must have an active Guild Finder recruitment listing for `$glink` to
be clickable.

Wrap an optional fragment in double square brackets. The whole fragment is
removed when one of its known tokens is empty:

```text
[[$progress progress · ]][[Discord: $discord · ]]Apply: $glink
```

Open **Guild profile** to maintain shared values. Use **Tokens** to insert a
token at the cursor.

## Why messages require a click

World of Warcraft requires a hardware event for messages sent to public
channels. RecruitRelay therefore reminds you when a message is due and displays
a button. Clicking the button sends one line. A two-line message needs two
clicks.

RecruitRelay does not simulate input or bypass Blizzard restrictions.

## Installation

Copy the `RecruitRelay` folder into:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

Restart the game and enable **RecruitRelay: Guild Recruitment**.

## Commands

- `/rr` or `/recruitrelay` — open the main window.
- `/rr send` — prepare a message and show the send button.
- `/rr reset` — reset the reminder timer.
- `/rr status` — print the current status.

## License

MIT

## Repository

Source code and releases:
[Frzok/RecruitRelay-Guild-Recruitment](https://github.com/Frzok/RecruitRelay-Guild-Recruitment).

## Local packaging

From the project directory on Windows:

```bat
package.bat
```

The version is read from `RecruitRelay.toc`, and the ready-to-install archive
is written to `dist/`.
