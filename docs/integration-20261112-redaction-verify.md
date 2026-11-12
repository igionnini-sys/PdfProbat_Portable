# Upstream integration, 2026-11-12: independent redaction verification

This batch follows [scanned-image cleanup](integration-20261112-scan-clean.md) and retains
all earlier corporate-fork integrations. The original exported workspace has no `.git`.
Its initial source backup, original patches, three-way merge records, inventories and
validation artifacts are under `target/upstream-integration-20261112-redaction-verify/`.

## Original source and adaptation

The feature comes from [d7ce875dd692109789bcdad1b683ffc5a2d07dc7, #5557](https://github.com/storytold/pdfcraft/commit/d7ce875dd692109789bcdad1b683ffc5a2d07dc7),
committed on 2026-11-06. Upstream was fetched again and checked at
`d749fd8062655c333c0733d8456bd8d4c9925a12` (2026-11-12). The original adds independent
snapshot, extraction, geometric checks and a bounded sweep, but has no engine, automation
or desktop callers at the checked revision.

The applicable follow-up source and regressions are also adapted:

| Commit | Purpose |
|---|---|
| `1d0c3034662aad0b697094afda59753237dba3af` | Decode indirect filter parameters in the proof |
| `0916bec6` | Read font streams with the same indirect parameters |
| `d2c87ae7`, `cf269804`, `4f107a6f` | Bounded, consistent reading of Form matrices, including indirect entries |
| `b16f0c0a`, `7c782226`, `042371bd` | Read applicable operands from the end, including referenced path points and MCIDs; retain the independent proof regressions |

All imports use three-way comparisons against the individual parents. Existing differences
in the fork are kept: conflicts involving absent pattern-pruning and Type 3 inheritance
machinery do not import that unrelated implementation. Two pattern-pruning tests, later
surviving-reference additions and an unrelated operator timing binary are consequently
omitted. Applicable operand, matrix and proof tests are retained. The proof's strict decoder
uses the fork's existing `Document::with_direct_parms` before its one-stream budget API,
preserving strict decoding and cumulative charging without changing every decoder caller.
Six proof files match the checked upstream main byte for byte after newline normalization.
Production adaptations are the decoder adapter and the privacy correction described below;
the proof tests retain the original metadata survivor fixtures because the later automatic
metadata-cleanup feature is not imported.

Upstream code retains its `MIT OR Apache-2.0` licence. The original dependencies are added:
`aho-corasick` pinned at 1.1.5 and the already-used `sha2` 0.11.1. No assets, fonts, brand
material or CI changes are imported.

## Engine, CLI/MCP and desktop

`Session::redaction_verification_job(original, output, pages)` captures a read-only worker
job; `Session::verify_redactions` runs it synchronously. The original must still have its
redaction marks. The job captures a snapshot, applies those marks to a **scratch** copy to
identify legitimate generated overlays, then sweeps the output. Neither open document is
edited, repaired or saved.

The subject is exactly what `Session::save_bytes` would write, including saved revision
history. Display bytes alone are insufficient: Undo can restore an older working graph while
a subsequent incremental save must still append to the last saved revision. A regression
checks that a saved metadata leak cannot disappear from the proof just because Undo no
longer displays it. For an unmodified reopened output, the bytes checked are the saved file.
No general full rewrite is substituted to make an adverse output appear clean.

The new read-only tool `redact_verify {doc, original, pages?}` returns `passed`, region
evidence, eight surface reports, survivor/unswept/unverifiable counts and failure locations.
A failed or incomplete proof is a valid result with `passed: false`; invalid documents or
page arguments produce actionable errors. Reports never include removed plaintext or
before-page hashes. `command_run` maps `redact.verify` to the same tool.

A local regression exposed an upstream privacy bug: an arbitrary Info dictionary key could
itself contain the secret and be echoed in both finding and unswept locations. Only fixed
standard field labels are now named; custom fields use an ordinal. The regression fails
before the fix, then passes for both surviving values and values nested beyond the walk
limit. Automation and real CLI/GUI checks cover a secret used as a custom metadata name.

**Redact a PDF → Verify redactions** opens the desktop dialog. The active document is the
output; a selector lists other open documents retaining marks. Verification runs on a worker
on native platforms and the original and output remain unchanged. The report is discarded
when either document changes or closes, including a change made while the worker ran. The
desktop shows a bounded, cached preview; the verdict always uses the complete proof.

To use it, mark the original, save a separate marked copy, open that copy and apply the
redactions there. With the result active, choose Verify redactions and select the still-marked
original. See [the automation example](../crates/automation/README.md#verify-redactions-independently).

## Evidence and limits

The sweep searches removed page-glyph strings in raw bytes, object strings, decoded streams,
independently extracted page text, Info, XMP, embedded files (nested PDFs included) and
revision history. It also checks surviving glyphs, images, paths, shadings and annotation
appearances inside the marked regions. Only hashes of overlay content generated from the
marked original authorize exemptions; forged output keys do not.

An unreadable or over-budget surface prevents a pass. Documented binary streams that the
proof cannot decode can be searched only as stored bytes and explicitly counted as `raw_only`.
The original limits remain: image-only text has no OCR search; guessed widths can over-report;
raw binary surfaces omit short needles, while structured text surfaces still check them;
legitimate retained occurrences have the original allowances. This adapter does not add
distinct removed annotation/field strings through `Snapshot::add_removed_strings`; it sweeps
those surfaces for the page-glyph needles. The lower-level API and its tests remain available.

The parity entry is **partial**, replacing its previous broad shipped claim with these
explicit limits. The existing automatic checks during Apply remain in place; this new,
independent multi-surface proof is an explicit, additional verification.

## Validation

Local Windows x64, Rust 1.95, existing craft-fonts and pinned craft-i18n; Cargo uses `--locked`
and two build jobs. The scoped suites pass **796 tests** in total:

- Redaction: 280 unit tests and the long-Form-matrix work regression pass. The single
  existing ignored test is a manual overlay timing probe.
- Content and fonts: 132 passing tests, including the new trailing-operand helpers and
  font streams with indirect decoding parameters.
- Engine: all four new API cases and nine existing redaction/OCR cases pass. The new
  cases check read-only behavior, invalid documents/pages, captured snapshots and the
  saved-history-after-Undo regression.
- Automation: all 360 integration tests pass, including successful save/reopen,
  unremoved text, residual metadata, argument refusal, unchanged documents and reports
  without removed plaintext. Earlier scan cleanup, OCR, comment and safety cases remain green.
- UI integration: three new verification cases and seven existing redaction cases pass.
  The tests cover a passing result, a visible failure, absent marked originals and
  invalidation of an earlier pass after an edit. The modal's Close is selected separately
  from the comments panel's equally named button.

Scoped Clippy for all targets of content, fonts, redact, engine, automation and UI passes
with `-D warnings`; the final UI wording is checked again. Formatting and the layering,
asset-attribution and parity gates pass. Native app, CLI and xtask builds succeed; engine
and UI compile for `wasm32-unknown-unknown` with the existing web warnings. Browser runtime
behavior is not qualified.

The actual CLI completes 43 steps: it verifies a marked-but-unapplied output as failed,
cleans and saves/reopens a result that passes, verifies through the common command mapping,
finds a restored metadata survivor, detects history retained after Undo and an incremental
save, and verifies encrypted outputs before and after reopening. Reports omit the removed
text, including when the secret is a custom metadata key; the marked original file stays intact. Cleaned, reopened and metadata-leaking outputs
have identical rendered PNGs, demonstrating that the extra survivor is invisible on screen.
The rendered output was visually inspected.

An isolated native instance is driven through opt-in `--control`. Its dialog chooses the
marked original, verifies a clean output as passed and a second, visually redacted output
with a secret used as a custom metadata key and value as failed. Fresh screenshots of the dialog and both reports were
inspected. Neither the report widgets nor machine-readable proof contain the removed text;
all documents remain clean, the source file is unchanged and the preview quits normally.

The adapted patch and before/after SHA-256 inventory pass `git apply --reverse --check`.
Debug app and CLI executables are updated; release/portable artifacts remain as before.

The pre-existing `license-check` gap remains: the exported source has no `LICENSES.toml`.
Asset attribution is checked separately. This is scoped local validation, not a full
workspace/CI or cross-platform qualification. Release binaries and the portable ZIP are not
regenerated by this source-integration batch.
