# Corporate fork: horizontal arrow navigation (2026-11-12)

Adapted upstream [`983e2f2ad6bfa4b7377163050f9b3fe16af980d3`](https://github.com/storytold/pdfcraft/commit/983e2f2ad6bfa4b7377163050f9b3fe16af980d3)
(#4540, November 5). Upstream `origin/main` was fetched and checked at
`d749fd8062655c333c0733d8456bd8d4c9925a12`. The three Rust files merged cleanly
against their common ancestor; existing fork changes were retained.

## Behaviour

- Left/right arrows pan an enlarged page horizontally by a line while more of the
  current page or spread remains in that direction. Scroll speed follows the existing preference.
- At the corresponding edge, the next press turns the page or spread. A wider next
  page opens at its left edge; a wider previous page opens at its right edge.
- A page that fits horizontally keeps immediate page turning. Ctrl+Left/Right
  (Command on macOS) turn immediately; Page Up/Down and view-history shortcuts retain
  their existing behaviour.
- Continuous view uses the current page's width, even beside much wider pages.
  Two-page view includes the second page even while it remains wholly off screen.
- Text inputs retain their arrow keys. The first and last pages stay in place when
  there is neither more content to pan nor another page. Navigation does not edit PDF bytes.

This is view state, implemented in `DocView` and the canvas scroll geometry. It is
available through the existing opt-in control API, `pdfcraft-cli ui key
key=ArrowRight` / `key=ArrowLeft`, and `ui.set` for zoom/layout. The production-order
control regression drives these requests end to end; no document-editing tool or
new listener is introduced. `view.page-navigation` cites the new evidence.

## Validation

- 334 passing scoped tests: 75 viewer integration tests, 196 canvas unit tests and 63 control integration tests (including the new production-order key regression).
- Clippy for all UI crate targets with `-D warnings`; workspace formatting check.
- Layering, asset attribution and parity gates passed.
- Native desktop, CLI and xtask build passed.
- Ten real GUI checks passed through the opt-in control channel: first/last-page bounds, horizontal panning in both directions, edge turns and entry edges, immediate Ctrl navigation, fitted-page navigation, text-focus routing and unchanged PDF bytes. Screenshots of both sides were visually reviewed; the isolated app quit cleanly.

The updated debug executable is `target/debug/pdfcraft.exe`; the portable release ZIP has not been rebuilt.

The previous debug executable reproduced the defect on a contributor-original
three-page synthetic PDF: ArrowRight immediately changed enlarged page 1 to page 2.
The same fixture is opened and rendered through four CLI steps. Generated PDFs,
renders, isolated profiles and control credentials remain under `target/`.

## Local review artifacts

`target/upstream-integration-20261112-navigation/` contains the pre-change backup,
source pins, original patch, three-way receipts, logs, CLI script/report, GUI state
trace and screenshots, changed-file hashes and the adapted patch with its reverse
check. No assets, fonts, dependency versions, CI workflows or release ZIP are changed.
