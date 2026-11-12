# Upstream integration, 2026-11-06: object generations and signature validation

This third selective batch follows [batch 2](integration-20261106-batch2.md) in the corporate
offline fork. Upstream main was fetched and remains at
`5aaa8186fd88d4c59f139665ff7809bd03775626`. The exported working directory has no `.git` history;
the source backup, original patches, adapted review patch and local validation logs live under
`target/upstream-integration-20261106-batch3/`.

## Original changes

| Change | Source | Adaptation |
|---|---|---|
| Resolve indirect references by object number and generation; preserve bounded repairs and shared identity on rewrite | [863af864](https://github.com/storytold/pdfcraft/commit/863af864a70f18bcf780a298f1e9923ee792c2ac) | Retain batch 2's fresh-identifier save policy while adapting document initialization and documentation. Include repair-aware PDF/A edits and original writer tests. |
| Judge later changes by the role and accepted generations of the signed object | [102cae3b](https://github.com/storytold/pdfcraft/commit/102cae3befb2df7f2dd6c3dc6eb46434104f9584) | Include the COS generation-query API, classification changes, original unit and signed-document regressions, and a bounded annotation-list budget. |
| A no-changes certification permits invisible document timestamps rather than further approval signatures | [9afa1266](https://github.com/storytold/pdfcraft/commit/9afa12665385d71009ccf351ad0101ad4553e03a) | Retain the original classifier and synthetic timestamp/signature regressions. |
| Preserve signed roles of catalog, page tree and form; detect removed fields, moved/hidden widgets and changed certification permissions | [5aaa8186](https://github.com/storytold/pdfcraft/commit/5aaa8186fd88d4c59f139665ff7809bd03775626) | Retain original classification and regression tests; add checks through `sign_list`. |
| Verify byte ranges when signing an encrypted file with earlier revisions | [0d7ae1b0](https://github.com/storytold/pdfcraft/commit/0d7ae1b0fc1fffa6d792193cddecff2920e03c46) | Include the original synthetic regression file, reusing the repository's existing test identity assets. No new key or certificate asset is imported. |

The code retains upstream authorship and its `MIT OR Apache-2.0` licence. No assets, dependencies,
CI changes, online services or update behavior are added. The first two integrations and this
fork's phone-pattern, CSV and offline customizations remain in place.

## Behavior and limits

An indirect reference now resolves only to an accepted generation of a live object. A missing,
free or unrelated generation resolves to null. A damaged live xref slot may accept both its row
generation and the same-number header at its indexed offset. Header probes are bounded to 128
bytes, and repair notes to 256 objects plus a summary. Repair-aware edits keep both aliases in
snapshots; full rewrites normalize them to one object rather than dropping or duplicating it.

Signature validation compares the later revision with what was signed. Relabeling a page-tree,
catalog, field or resource object cannot disguise its role. It detects stale-generation references,
removed fields, moved or hidden widgets, and approval signatures following a no-changes
certification. Genuine form filling remains allowed at the corresponding permission level.
Shared annotation lists consume a bounded budget; if the comparison cannot establish an allowed
change within its bounds, it refuses the change rather than reporting it as allowed.

The engine's existing signed-rewrite guard remains: an edit of a repaired signed slot that would
require a full rewrite is refused without adopting the edit. An unsigned file can be repaired and
saved. These corrections use existing headless tools (`doc_open`, `form_fill`, `doc_save`,
`sign_document`, `sign_list`); they add no new user-facing tool or network transport.
Document timestamp creation remains partial in parity: transport is caller-injected and this
batch adds no timestamp-server configuration or automation tool for timestamp creation.

## Validation

Validation uses the local Windows x64 Rust 1.95 toolchain, existing craft-fonts and pinned
craft-i18n build inputs, `--locked` and two build jobs.

- Before changing production code, original signature regressions reproduced 26 failing tests
  (12 unit and 14 signed-document cases); a COS regression also reproduced an unrelated
  generation resolving incorrectly. The old shared-annotation stress test exceeded 60 seconds
  and was stopped; the baseline rerun skipped only that stress case.

- COS, signatures, preflight and redaction suites: 601 passing tests, six pre-existing ignored
  cases. All 27 reproduced failures now pass. The shared-annotation stress regression also
  passes its original 20-second assertion; the complete signature unit suite took 4.88 seconds.
- Complete automation integration binary: 342 passing tests, including four new public-tool
  tests. They cover allowed form filling versus hidden/moved widgets, removed/dead-generation
  fields, a further approval after P=1 certification, repair-aware alias preservation and refusal
  of a signed rewrite with the original bytes intact. Total: 943 passing tests.
- Scoped Clippy passes with `--all-targets -- -D warnings` for COS, signatures, preflight,
  engine and automation. Formatting passes; COS also compiles for `wasm32-unknown-unknown`.
- Architecture, asset attribution and parity gates pass. The asset gate uses the existing
  `target/build-tools/asset-index.git` because this directory is an exported checkout.

- A Windows development build of `pdfcraft` and `pdfcraft-cli` succeeds. Release binaries,
  installer and portable ZIP are not rebuilt in this batch.
- The updated CLI passes 18 confined script steps: creates and explicitly trusts a synthetic
  identity, certifies a document, reopens separately appended revisions, permits a form-value
  change and detects hidden/moved widgets as disallowed page-content changes. The signed source
  is checked unchanged. Certified, filled and moved-field page renders were visually inspected.
- The updated app was launched with opt-in `--control`, an isolated portable profile and system
  fonts disabled. The real signatures panel marks the moved-field certification invalid and
  explains the disallowed page-content change. Its screenshot was inspected and the preview
  was closed without changing the user's settings or documents.
- A byte comparison against the pinned upstream source confirms exact matches for the six
  principal adapted files (reader API, open/save policy, writer, classifier, preflight and COS
  documentation); hashes are recorded in `upstream-source-check.json`.
- The local `adapted.patch` passes `git apply --reverse --check`; `changed-files.json` records
  before/after hashes beside the source backup and validation logs.

This is scoped native validation, not a full workspace/CI run or cross-platform qualification.
The larger OCR-engine/review integration remains outside this batch.
