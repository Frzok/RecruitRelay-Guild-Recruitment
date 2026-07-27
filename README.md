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
- Automatic queuing through MessageQueue when it is installed.
- Russian and English interfaces.
- No external addon dependencies.
- A reusable guild profile for schedules, progress, contacts, and links.
- Modern dark interface with clear profile and recruitment sections.
- Color-coded recruitment selectors for days, roles, classes, specializations, and activities.
- Automatic guild roster counters.

## Message tokens

| Token | Replacement |
| --- | --- |
| `$gname` | Current guild name |
| `$glink` | Clickable Guild Finder link, or guild name as a fallback |
| `$player` | Current character name |
| `$time` | Current local time |
| `$raidtime` / `$schedule` | Manual raid time or generated schedule |
| `$days` | Selected schedule days |
| `$progress` | Guild progress |
| `$requirements` | Recruitment requirements |
| `$contact` / `$backupcontacts` / `$contacts` | Recruiter contacts |
| `$discord` / `$website` / `$voice` | Community links and voice chat |
| `$focus` / `$activities` | Guild focus and selected activities |
| `$needs` / `$roles` / `$classes` | Compact recruitment needs, including selected specializations |
| `$priority` | Priority recruits |
| `$about` | Short guild description |

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
channels. When the optional
[MessageQueue](https://www.curseforge.com/wow/addons/messagequeue) addon is
installed, RecruitRelay automatically queues a due announcement. It is sent on
your next normal mouse, keyboard, or gamepad input without clicking a
RecruitRelay button.

Without MessageQueue, RecruitRelay displays its own send button as a safe
fallback. RecruitRelay does not simulate input or bypass Blizzard restrictions.
Use **Disable announcements** to stop the timer and cancel a queued
RecruitRelay action before it runs.

## Installation

Copy the `RecruitRelay` folder into:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

Restart the game and enable **RecruitRelay: Guild Recruitment**.

Install and enable **MessageQueue** as well to use automatic queuing. The addon
continues to work without it, but public announcements then require the
RecruitRelay send button.

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
