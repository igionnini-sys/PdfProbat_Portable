# Upstream integration, 2026-11-06: OCR engines, preprocessing and review

This fourth selective batch follows [batch 3](integration-20261106-batch3.md) in the corporate
offline fork. It adapts the original [OCR integration, 9f04accc / #977](https://github.com/storytold/pdfcraft/commit/9f04accceff67174fc2817035f8ab4577bef8285),
checked against upstream main `5aaa8186fd88d4c59f139665ff7809bd03775626`. The exported input has
no `.git` history. Original sources, SHA-256 inventory, upstream patches, the adapted review
patch and validation logs are retained under `target/upstream-integration-20261106-batch4/`.

## Adaptation

- Integrate the recognizer interface, built-in ocrs adapter and optional external Tesseract
  adapter; confidence bands and bounded confidence-weighted/ROVER merging.
- Integrate opt-in rotation, deskew, denoise and binarization before recognition, mapping word
  boxes back to the original page through the inverse transform.
- Integrate Unicode-preserving searchable layers and editable-text output using the existing,
  attributed embedded craft-fonts faces. No font asset is added.
- Integrate the OCR Verify screen: review and correct words, inspect confidence, remove or
  restore words, use a per-language dictionary, re-read a page or region, and accept/reject.
  Stale-document checks protect acceptance; accepted searchable output is undoable.
- Integrate headless review/dictionary tools and extended OCR settings, with the original
  end-to-end regressions. Existing tools gain engine selection, preprocessing, skip/force
  controls, output choice and region recognition.
- Adapt seven source files around this fork's command catalogue, edit dispatch, app lifecycle
  and workflow modules. The fork's separate Enhance scanned file feature remains unimplemented;
  importing OCR preprocessing does not mark that separate feature ready.
- Set English explicitly in the two new review-screen tests in both UI test entry points,
  as the existing dialog tests do; English queries must not depend on the Windows language.
- Simplify the positive/finite geometry guard in the OCR layer for the fork's Clippy version.
- Keep the review toolbar above all panes. A real 1440-pixel preview exposed clipped actions
  and a letter-wrapped Binarize label when the original toolbar shared the source pane's width.

The code retains upstream authorship and the `MIT OR Apache-2.0` licence. The original screenshot,
its attribution entry, screenshot generator changes and generic upstream README/roadmap changes
are not imported. This batch adds code and documentation only, retaining the corporate branding,
offline policy, first three integrations and local phone/CSV behavior. CI is unchanged.

The source licence checker follows the model filename constants from `ocr/src/lib.rs` to the
new `ocr/src/ocrs.rs` module. Existing model files and attribution remain unchanged. PNG, needed
to send an image to an external recognizer, already exists in the lockfile; its use by OCR and
the UI's direct OCR dependency are the only dependency-graph additions.

## Behavior and limits

The default remains the built-in ocrs engine, English and searchable output. Preprocessing is
off by default. Searchable acceptance leaves the scan image unchanged; editable output writes
a separate new PDF and refuses to replace the source or another existing file. Unsupported
editable glyphs are reported as substitutions; searchable output preserves Unicode through
empty Type3 character programs and ToUnicode maps.

Tesseract is optional: it is never downloaded, installed, linked or bundled. A configured
absolute program path or a validated PATH entry selects a local executable. Language choices
are allow-listed and still depend on its installed language packs. The wrapper uses private
temporary files, a minimal environment, timeout and output caps. The upstream limit remains:
timeout/cap cleanup kills the direct child, not any children created by a wrapper program.
Tesseract is absent on this validation machine, so no real Tesseract run or non-English OCR
qualification is claimed. The built-in models are present locally and used for English tests.

`ocr_words` with `retain_review` returns a bounded session-local review handle;
`ocr_review_apply` accepts corrections at the retained boxes or discards the result, and
`ocr_dictionary` atomically updates an explicitly root-confined dictionary file. Review handles
cannot be replayed or applied to stale/foreign documents. Dictionary additions are deliberate
user actions and persist locally outside the PDF. Suggestions, verified marks and region
re-read interactions remain UI-only, as recorded in the original partial parity entry.
Browser OCR and the separate deep scan-cleanup tools remain outside this batch.

## Validation

Windows x64, local Rust 1.95, existing craft-fonts and pinned craft-i18n build inputs; Cargo
builds/tests/Clippy use `--locked` and two build jobs. Models are the already-present local pair.

- OCR, fonts and edit suites: 625 passing tests, including preprocessing transforms, confidence
  and merging rules, bounded images/text planning, Unicode layers and editable glyph output.
  Conditional installed-Tesseract tests cannot prove its process path on this machine; the
  wrapper's fake-process timeout/cap/environment regressions are Unix-only.
- Engine OCR regressions: 50 passing tests, exercising real local recognition, retained
  review guards, Unicode layers, save/undo and editable output.
- The complete automation integration suite: 349 passing tests, including the seven new OCR
  review/dictionary cases and the regressions from the first three batches.
- UI OCR tests: 49 unit tests, 14 integration cases in the shared suite and 6 cases in the
  standalone entry point (the latter includes duplicated dialog/review coverage).
- Redaction: the synthetic Type3 OCR-layer regression passes. The OCR crate's 84 tests were
  rerun after the Clippy geometry adaptation and pass.
- A 22-step real CLI script recognizes a synthetic scan, corrects and saves its searchable
  layer, reopens the saved correction, creates and renders an editable copy, updates a local
  dictionary and writes a batch copy. Before/after searchable PNGs are byte-identical.
  Both source and editable render artifacts were inspected visually.
- The isolated desktop preview runs the real local OCR, changes `Review` to `GuiCorrected`
  through the word inspector, accepts it, exits review and undoes the acceptance in one step.
  A screenshot confirms the full-width toolbar and correction; control-widget bounds confirm
  the actions are inside the 1440 x 920 window. The preview quits cleanly with no dirty document.
- Engine and UI compile for `wasm32-unknown-unknown`; this is a compilation check, not a claim
  of browser OCR runtime support.
- Eleven licence-checker unit tests pass, including the required model filename/metadata tests.

Layering, assets and parity pass with the rebuilt xtask. The extra `license-check` command
cannot complete because this exported fork lacks `LICENSES.toml`, which its existing checker
already requires. This is recorded as an existing validation gap, not a successful check;
the model filename checks have been adapted to the split OCR module.

The six standalone UI tests pass again after the toolbar adaptation. Clippy with `-D warnings`
passes for all targets of OCR, fonts, edit, engine, automation and UI. Workspace formatting,
the final native app/CLI/xtask build and a final engine/UI WebAssembly check pass. No test is
ignored in the scoped runs; the installed-Tesseract conditional limitation above still applies.

The 58-file adapted patch passes `git apply --reverse --check` against this checkout. Its
before/after SHA-256 inventory and the original upstream patch are retained with the backup;
31 of the 54 imported source files remain byte-identical to the pinned original. Other files
retain fork changes or the documented adaptations. No assets or CI files change.

This is scoped local validation, not a full workspace/CI or cross-platform qualification.
The desktop app, CLI and xtask were rebuilt in the debug profile. Release executables and the
portable ZIP in `dist/release/` are not regenerated by this source-integration batch.
