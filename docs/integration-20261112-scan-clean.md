# Upstream integration, 2026-11-12: scanned-image cleanup

This selective batch follows [the comment and Fill & Sign integration](integration-20261106-batch5.md).
It adapts [upstream commit 419b267ee5f2e1b2bb6860cfa997faf5460f3111](https://github.com/storytold/pdfcraft/commit/419b267ee5f2e1b2bb6860cfa997faf5460f3111)
(Enhance scanned file, #5125) to the corporate offline fork. Upstream main was checked at
`d749fd8062655c333c0733d8456bd8d4c9925a12`; there were no later changes to the scan-clean
engine, its tests, the dialog or the sample decoder/encoder at that revision.

The exported workspace has no `.git` history. Its initial source backup, SHA-256 inventory,
original patch, three-way adaptation records and validation logs are retained under
`target/upstream-integration-20261112-scan-clean/`. All 31 selected crate source files merged
cleanly against the original commit's parent, retaining the five previous integrations and
corporate customizations. Upstream code keeps its `MIT OR Apache-2.0` licence. No assets,
font files, dependencies or CI changes are imported.

## Behavior and access

**Scan & OCR → Enhance scanned file** (`ocr.enhance`) provides page selection, background
removal strength (0–100), edge shadow removal and despeckling. The work runs in a cancellable
background job and reports both changed images and images left alone with their reasons.
The engine exposes `Session::scan_clean_job`, `ScanCleanJob::run`, `Session::apply_scan_clean`
and the synchronous `Session::enhance_scanned_pages`. CLI and opt-in MCP expose the same
operation through `page_enhance_scan`; see [the automation example](../crates/automation/README.md#enhance-scanned-pages).

The scan image objects are rewritten in place at their original dimensions and colour space.
Page content streams, invisible OCR text, links, annotations, form fields and image masks are
retained. No page is flattened or replaced with a raster. All changed images form one undoable
edit, **Enhance scanned file**. With every filter off, there is no edit. JPEG scans remain JPEG
at quality 90; other supported images use lossless Flate; bilevel images remain one bit deep.

Background removal evens the paper's illumination and strengthens faint strokes; edge shadow
removal works on the outer fifth of the image. Despeckle removes isolated dark pixels with at
most one dark neighbour. Defaults are level 50 with edge cleanup on and despeckle off; the
headless tool enables despeckle by default from level 60. The switches are independent.

Two local safety adaptations supplement the original code:

- Results belong to their originating document **and** byte-buffer snapshot, in addition to
  the edit-generation check. Another document with the same generation, or another session
  reusing the same numeric document ID, is refused without an edit. Two synthetic regressions
  fail against the original implementation and pass with the document/snapshot guard.
- A cancel request received while the final image is being processed is honored before
  applying its completed result. A queued-result regression checks unchanged bytes and no
  undo entry.

## Deliberate limits

Parity entries for background removal, edge shadows and despeckle remain **partial**. Supported
inputs are 8-bit grey/RGB raw, Flate and JPEG, plus 1-bit grey raw/Flate for despeckling. CMYK,
indexed colour, JPEG 2000, JBIG2, CCITT, colour-key masks, remapping Decode arrays and scans
inside grouped Form artwork are left alone with a reason. Broken, oversized (over 80 million
pixels) or operation-budget-exceeding images are reported rather than forced through decoding.
Pages count as scans when pictures cover at least half their area; pictures covering at least
a tenth are cleaned. Larger specks and a before/after preview are not implemented.

An image object shared by multiple pages is cleaned only once. Consequently, cleaning one
selected page also affects unselected pages drawing that same image object; the original
shared-image regression records this behavior. The report lists pages requested by the caller.
Save to a separate filename to retain the source file; ordinary undo/redo is also available.

## Validation

Local Windows x64, Rust 1.95, existing craft-fonts and pinned craft-i18n inputs; Cargo uses
`--locked` and two build jobs. Logs, scripts, reports and synthetic renders are retained in
the local work directory.

- The complete optimize suites pass 112 tests (30 unit, 5 content-boundary, 77 image tests).
  Engine scan and camera selections pass 61 distinct tests, including all 13 scan-clean
  cases: grey/RGB/JPEG/bilevel cleanup, image masks and properties, encrypted files,
  permission refusal, malformed images, page selection, shared images, stale results and
  the two document/snapshot regressions.
- All 356 automation integration tests pass. The added preservation case checks nonempty
  OCR text, a URI link, a comment and a populated field; every non-image object in the
  working graph is unchanged. It then saves/reopens, checks the same text/link/comment/field
  data and cleaned image samples, and checks undo/redo and an untouched source file.
  Save As legitimately renumbers indirect objects, so graph comparisons use the working
  snapshot while reopened checks follow the public APIs and image data.
- UI integration passes both scan-clean cases and all six existing camera cases. Seven
  UI unit cases pass, including cancellation of a completed-but-unapplied job, invalidation
  of the displayed scan raster and mutual exclusion with optimization.
  The scoped suites therefore pass 544 distinct tests in total; none is ignored.
- Scoped Clippy for all targets of optimize, engine, automation and UI passes with
  `-D warnings`. Workspace formatting and the layering/assets/parity gates pass.
- Native app, CLI and xtask build successfully. Engine and UI compile for
  `wasm32-unknown-unknown` with the existing web warnings; browser execution is not qualified.
- The actual CLI passes 22 steps on a synthetic scan containing OCR, a link, a comment
  and a populated form field. It cleans, saves/reopens, undoes and redoes, and checks all
  filters off as a no-op. The reopened and redone PNGs equal the cleaned PNG byte for byte;
  the undone and no-op PNGs equal the source render. The source file remains unchanged.
  The before/after images were visually inspected: background, gutter shadow and isolated
  speck disappear, while dark strokes, annotation and field text remain.
- An isolated desktop instance is driven through opt-in `--control`: open the dialog,
  drag background strength to 100, enable despeckle, run the background worker, undo and
  redo in one step, then undo and quit cleanly. Fresh captures after asynchronous raster
  completion show the original shadow/speck after Undo and clean paper after Redo, with
  the comment and form still present. The preview process exits normally.

The 38-file adapted patch passes `git apply --reverse --check`; before/after SHA-256
inventories and the initial backup are retained. Debug app and CLI executables are updated.

The pre-existing source-wide `license-check` gap from batch 4 remains: this exported workspace
has no `LICENSES.toml`. This batch does not claim to close that separate manifest gap or to
audit completed release packages. Validation is scoped locally, not a full workspace/CI or
cross-platform qualification. Release binaries and the portable ZIP are not regenerated.
