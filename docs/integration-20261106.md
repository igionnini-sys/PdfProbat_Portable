# Upstream integration, 2026-11-06

This first batch adapts three changes from `storytold/pdfcraft` to the corporate offline fork.
It is a selective source update, not a merge of the whole upstream branch. The input directory
has no `.git` history. A ZIP of the original sources and a SHA-256 inventory are retained under
`target/upstream-integration-20261106/`; that directory also holds the original patches and local
validation logs.

## Original changes

| Change | Source | Adaptation |
|---|---|---|
| Security-handler revision determines printing, accessibility, form-filling and page-assembly permissions | [ee39c7e2 / #6309](https://github.com/storytold/pdfcraft/commit/ee39c7e2d01787c70c521c2a7392790498606cf0) | Preserve the revision when reporting pending protection settings; retain the original flag-table regressions. |
| Search and Redact recognizes IBANs | [f9c150c1 / #4332](https://github.com/storytold/pdfcraft/commit/f9c150c17c2f717e0795b0820b1d5d4fba79f660) | Retain this fork's Italian telephone-pattern corrections and tool definitions. The pattern schema comes from the engine registry. |
| Form dates use the selected language for month and weekday names | [6427357f / #5464](https://github.com/storytold/pdfcraft/commit/6427357fcb184ef4da93e78b3dda6d16bd7a0ab5) | Retain local form/CSV changes. Add `form_date_language` to the existing CLI/MCP table, with an isolated end-to-end test. |

The source commits retain the original authorship and are licensed under the upstream project's
`MIT OR Apache-2.0` licence. No upstream logos, screenshots, fonts or other assets were imported.

The date-language API supplied by upstream is process-wide. The desktop updates it from its date
preference; CLI/MCP callers explicitly select it with `form_date_language`. Selecting a language
does not rewrite saved appearances or modify field values. Subsequent formatting accepts English
as well as localized input and uses English output when the field font cannot draw localized
names. The setting is not isolated per open document or per `Automation` object.

## Existing fixes retained

The source audit found the OCR-under-scan fix (#5396), structure-title cleanup (#5866), removal of
`/PCAdded` from rewritten form XObjects (#5868), and optimization beneath stencil masks (#5847)
already present, including their regression tests. They were not reapplied.

The larger OCR-engine/review update and the latest signature-classification changes are not part
of this batch. In particular, the signature changes depend on upstream's object-generation work;
this integration makes no claim to include them.

## Repository checks

Two pre-existing inconsistencies were corrected while running the repository gates:

- The contributor-original Windows portable guide's attribution hash was stale. Its contents and
  recorded provenance were checked and the hash refreshed; `ATTRIBUTION.md` was regenerated.
- The offline fork disables update checks, but parity still claimed the upstream online behavior
  and cited removed tests. That entry now records the feature as out of scope for this fork and
  cites the existing enterprise-policy tests.

Two existing formatting differences in `chrome.rs` and the asset-gate test were normalized.
Existing Clippy findings were also resolved with equivalent match guards, `Option` fallbacks and
boolean expressions in image-path handling and the UI. Two unused UI helper functions with no
callers were removed. No network or update implementation was imported.

## Validation

Validated on Windows x64 with the repository's local Rust 1.95 toolchain and existing craft-fonts
and pinned craft-i18n build inputs. Builds, tests and Clippy used `--locked` and two build jobs.

- Before the permission patch, the original new regressions ran against the fork and reproduced
  five failures: assembly, high-quality printing, revision-2 accessibility, form filling and
  later-revision flags. The corrected implementation passes all nine permission regressions.
- `cargo test -p pdfcraft-crypt -p pdfcraft-js -p pdfcraft-forms -p pdfcraft-redact`: 544 passed,
  one pre-existing ignored JavaScript test; includes the IBAN checksum and national-length tests.
- Engine `form_date_language` integration binary: nine passed, including localized/English
  round trips, unsupported field-font fallback, ambiguous names and hostile input.
- Automation `form_date_language` integration binary: one passed, covering invalid settings,
  Italian appearances, preserved values, save/reopen and rendered pixels.
- Automation regression groups (`redact`, `protecting_through_tools`,
  `form_formats_and_calculations`, advertised pattern schema): 16 passed, including this fork's
  Italian telephone-number behavior and the new IBAN end-to-end test.
- UI integration tests filtered by `date`: 25 passed, including the offline update-policy tests.
- Formatting and scoped Clippy for all targets of crypt, JS, forms, redact, engine, automation
  and ui-egui pass, with `-D warnings` for Clippy.
- Layering, asset and parity gates pass. With no `.git` checkout, the asset gate used the
  pre-existing local asset-index repository in `target/build-tools/asset-index.git`.
- A Windows release build of `pdfcraft` and `pdfcraft-cli` succeeded. Existing unused-helper
  warnings from that build were subsequently removed by the lint-only cleanup above, which was
  validated by Clippy and UI test compilation. An installer/portable ZIP was not repackaged.
- The updated release CLI ran a confined 15-step synthetic script: created a form, formatted an
  Italian date, added a sample Italian IBAN, marked/applied redaction, saved and rendered it, and
  extracted the result. Both renders were visually inspected: the date remains `18-ott-26`,
  only the IBAN is covered, and the extracted text no longer contains the account number.
- The release app was launched with `--control` and an isolated portable profile, with system
  fonts disabled. `pdfcraft-cli ui` inspected and captured the real interface, selected the IBAN
  pattern and marked the synthetic account. The test mark was undone and the preview closed.

The three original upstream patches also pass `git apply --reverse --check`, confirming that
their changes remain intact after adaptation. These are scoped native checks, not a full
workspace/CI run or qualification on other platforms. Logs and local synthetic outputs remain
under `target/upstream-integration-20261106/`; none is published in this integration.
