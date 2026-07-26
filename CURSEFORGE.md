# RecruitRelay: Guild Recruitment

RecruitRelay is a lightweight, standalone guild recruitment broadcaster for
World of Warcraft Retail.

## Build better recruitment messages

Write an announcement once and use dynamic tokens:

- `$gname` — your guild name
- `$glink` — a clickable Guild Finder application link
- `$realm` — your realm
- `$faction` — your faction
- `$player` — your character name
- `$online` / `$members` — online and total guild members
- `$schedule` — days and times selected in the schedule builder
- `$needs` — selected roles and classes
- `$progress`, `$requirements`, `$contacts` — your saved guild profile
- `$discord`, `$website`, `$focus`, and many more

The live preview shows the final message and checks WoW's 255-byte limit before
anything can be sent.

## One guild profile, every message

Save your raid schedule, progress, recruitment requirements, contacts,
community links, language, region, guild focus, voice chat, loot rules, and
other details once. Insert them into any message from the built-in token
palette.

The visual recruitment builder creates role, class, activity, and schedule
text automatically. Optional blocks such as `[[Discord: $discord]]` disappear
when their data is empty, keeping announcements clean.

RecruitRelay can also display the current online and total guild roster counts.

## Safe reminder workflow

Choose General, Trade, or Looking For Group and set a reminder interval.
RecruitRelay rotates through the selected available channels.

When an announcement is due, a movable button appears. Click it to send the
message. This intentional interaction follows Blizzard's hardware-event
requirement for public channel messages.

RecruitRelay pauses reminders while you are:

- in combat;
- inside a dungeon, raid, scenario, battleground, or arena;
- AFK.

## Clickable Guild Finder links

If your guild has an active Guild Finder recruitment listing, `$glink` becomes
a clickable in-game link. Players can open the listing and submit an
application. If no active listing is available, RecruitRelay safely falls back
to the plain guild name.

## Other details

- WoW Retail 12.0.7
- English and Russian
- No external dependencies
- No input simulation or automated spam
- MIT licensed

Open the addon with `/rr` or `/recruitrelay`.
