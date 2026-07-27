# Changelog

## 1.2.0 — 2026-07-27

- Added a one-click way to disable scheduled announcements from the send reminder.
- Clearing announcements now also dismisses any pending message.
- Rebuilt all addon windows with an original navy-and-amber RecruitRelay theme.
- Added compact horizontal navigation instead of a reference-style side menu.
- Guild profile and token palette now open as separate screens instead of
  overlapping the main window.
- Returning from a secondary screen preserves the unsaved message draft.
- Separated the guild profile into details and recruitment tabs.
- Added a visible class-color recruitment grid with checkboxes.
- Added a dedicated class and specialization tab with localized specialization names.
- Recruitment tokens now use compact role and class names such as MDPS, RDPS,
  Heal, DK, DH, МДД, РДД, Хил, Вар, Пал, and Дракон.
- Selected specializations are shown after their class in `$classes` and `$needs`.
- Simplified the token palette by hiding removed profile fields and low-value
  technical tokens.
- Added localized hover explanations to every token shown in the palette.
- Replaced the separate token screen with a compact in-place palette that keeps
  the announcement visible and stays open while several tokens are inserted.
- Removed language, time zone, region, age, and loot fields from the profile UI.
- Fixed status and validation text overlapping the bottom action buttons.
- Added optional MessageQueue integration for automatic sending on the next
  normal player input.
- Kept the dedicated send button as a fallback when MessageQueue is unavailable.

## 1.1.0 — 2026-07-26

- Added a reusable guild profile.
- Added automatic `$online`, `$members`, `$time`, and `$date` tokens.
- Added schedule, contact, progress, requirements, community, and guild detail tokens.
- Added visual selectors for days, roles, classes, and activities.
- Added generated `$schedule`, `$needs`, `$roles`, `$classes`, and `$activities` values.
- Added a token palette that inserts values at the message cursor.
- Added optional `[[...]]` fragments that disappear when their tokens are empty.

## 1.0.0 — 2026-07-26

- Initial public release.
- Added recruitment message composition and live preview.
- Added `$gname`, `$glink`, `$realm`, `$faction`, and `$player` tokens.
- Added Guild Finder listing loading and clickable application links.
- Added General, Trade, and Looking For Group channel rotation.
- Added 5–60 minute reminder scheduling.
- Added combat, instance, and AFK safety pauses.
- Added hardware-action send button for Blizzard-compliant public chat posting.
- Added English and Russian interfaces.
