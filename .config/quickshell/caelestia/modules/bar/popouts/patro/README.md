Bikram Sambat date logic vendored verbatim from https://github.com/yogeshojha/patro
(MIT, see LICENSE) at commit 9c070942c6849a4fffc8110568f72820f365ba74 (2026-08-17).

- Bikram.js        BS <-> AD conversion, month grid
- CalendarData.js  month-length table, BS 2000-2090 (2084+ provisional)
- Nepali.js        Devanagari numerals, month/weekday names

Used by ../NepaliCalendar.qml. To update, copy the three files from upstream again;
CalendarData.js is generated there by tools/build-table.js, don't hand-edit.
