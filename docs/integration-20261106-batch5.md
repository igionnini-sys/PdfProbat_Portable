# Upstream integration, 2026-11-06: comments and Fill & Sign

This fifth selective batch follows [the OCR integration](integration-20261106-batch4.md).
It adapts the original comment and Fill & Sign changes to the corporate offline fork. The
exported workspace has no `.git` history. A source backup, SHA-256 inventory, original patches,
three-way adaptation records and local validation logs are kept under
`target/upstream-integration-20261106-batch5/`.

## Original changes

| Change | Original commit |
|---|---|
| Independent text, border/line and fill opacities | [c3c36f77 / #4542](https://github.com/storytold/pdfcraft/commit/c3c36f77) |
| Copy/paste comments between documents, multiple selection and connected-line completion | [42bc4f11 / #3484](https://github.com/storytold/pdfcraft/commit/42bc4f11) |
| Fill & Sign text border width and its own colour | [0839c1e7 / #4146](https://github.com/storytold/pdfcraft/commit/0839c1e7) |
| Rectangular, oval and circular text borders | [496e37d7 / #4543](https://github.com/storytold/pdfcraft/commit/496e37d7) |
| Shift constrains drawing to horizontal or vertical | [96fe832e / #4285](https://github.com/storytold/pdfcraft/commit/96fe832e) |
| Double-click comment text to edit it | [04cee34b / #4544](https://github.com/storytold/pdfcraft/commit/04cee34b) |
| Escape deselects and leaves Fill & Sign tools | [8d569066 / #4539](https://github.com/storytold/pdfcraft/commit/8d569066) |

The original source hunks merge cleanly in three-way comparisons with their individual parents.
Only the selected crate changes and twelve corresponding parity entries are adapted. The code
retains upstream authorship and its `MIT OR Apache-2.0` licence. No assets, dependencies or CI
changes are imported. The previous four integrations and corporate customizations are retained.

## Adaptation and behavior

The engine exposes the new edits; `comments_copy` returns the selected comments and their
replies as XFDF, and `comments_paste` adds new copies to a specified page. It preserves the reply
relationships, assigns fresh names, and applies one undoable step. Optional `at` positions the
bundle's centre using displayed-page coordinates. Repeated pastes add new sets.

`comment_add`, `comment_edit`, `comment_list` and `fill_sign_add` expose the new applicable style
controls. The desktop supports multiple comment selection, group movement/deletion/property
changes, clipboard placement and the new text border controls. Make Properties Default stores
the supported settings. Callouts keep rectangular borders; other viewers show the generated
appearance, but a viewer that rebuilds it may use a rectangular border or one opacity.

An additional combined-feature regression found that the original clipboard lost `/ca` (the
fill's opacity) and `/RD` (the text inset inside an oval/circular border). The private
`pdfcraft:keys` clipboard extension now carries only these explicitly allowed standard keys
alongside the existing PdfCraft keys. Their values must be finite, valid numeric values;
references, malformed arrays and unrelated standard keys remain excluded. A synthetic test
reproduced the missing fill opacity before the fix, then checks all three border shapes after
copying, saving and reopening. Another regression checks hostile extension values. Ordinary
XFDF export keeps its original standard-only behavior.

The real rendered-copy check also exposed a visible note icon on copied replies: import drew
each note before attaching its parent. Linked Text replies now receive the empty appearance
used by the annotation API. Standalone orphan replies and grouped annotations retain their
visible appearances. The synthetic attached/orphan regression fails before this correction
and passes afterwards; the final rendered copy is pixel-identical to the source.

The original limits remain explicit in parity: no marquee selection; copies redraw supported
comment appearances rather than copying arbitrary appearance streams; attachment comments do
not bring their embedded file data; browser clipboard exchange across tabs is unqualified.

## Validation

Windows x64, local Rust 1.95, existing craft-fonts and pinned craft-i18n inputs. Cargo commands
use `--locked` and two build jobs.

- Annotation and measurement suites pass 128 tests. The final XFDF suite passes 86 tests,
  including three additional clipboard regressions: 214 core tests in total.
- Engine comment tests: 16 passing cases, including copied replies, independent names,
  invalid-input refusal, an untouched source and paste undo.
- The full automation integration suite passes 354 tests after the local adaptations,
  including the original clipboard, opacity, border and orthogonal-line end-to-end tests.
- UI integration suites pass all 120 comment and 51 Fill & Sign cases. The two copied-comment
  interaction cases pass again after the reply-appearance correction. There are 755 passing
  tests across the scoped suites, excluding repeated runs; none is ignored.
- Scoped Clippy for all targets of annotation, measurement, XFDF, engine, automation and UI
  passes with `-D warnings`. Workspace formatting and layering/assets/parity gates pass.
- The final native app, CLI and xtask build succeeds. Engine and UI compile for
  `wasm32-unknown-unknown`; browser runtime clipboard behavior is not qualified.
- The actual CLI completes 32 steps on synthetic files. It copies all border styles,
  independent opacities and a reply, saves/reopens, pastes twice with fresh names, and undoes
  both a paste and a combined property edit. Source, pasted, reopened and undone PNGs are
  byte-identical. The source file is checked unchanged; the renders were visually inspected.
- The isolated desktop preview changes border shape and fill opacity in Properties, undoes
  both in one step, copies a comment with its reply to a second open document, places and
  selects the copy, and undoes the paste. Screenshots of the controls and placed copy were
  inspected. It quits with both documents clean and the process exits.

The source-wide `license-check` gap recorded in batch 4 remains: the exported workspace has
no `LICENSES.toml`. Asset attribution passes; this batch does not claim to close that separate
manifest gap or to audit completed release packages.

The 60-file adapted patch passes `git apply --reverse --check`; its before/after SHA-256
inventory is retained with the original patches and source backup. No assets or CI files change.

This is scoped local validation, not a full workspace/CI or cross-platform qualification.
Release binaries and the portable ZIP are not regenerated by this source-integration batch.
