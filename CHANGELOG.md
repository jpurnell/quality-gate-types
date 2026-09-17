# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.5.0] - 2026-09-17

### Added
- `Diagnostic.endLine` — the last line of the region a diagnostic covers, with `lineSpan`
  (an inclusive `ClosedRange<Int>?`) and `lineCount` derived from it.

  A diagnostic has only ever carried a point. That is not enough to answer "how many lines did
  this rule flag?", which is what a ratio of flagged lines to SLOC needs. Counting a
  `function-body-length` finding over a 40-line body as one line makes such a ratio a near-pure
  function of clone lines; counting it as forty makes it a function of the long-declaration
  rules. Either way the number is an artifact of an unstated choice. See
  `ARatioNeedsAPopulation.md` in the quality-gate-swift companion.

  **`nil` means "this rule does not report a region", never "one line."** A rule whose finding
  genuinely covers a single line says so by setting `endLine` equal to `lineNumber`. Absence is
  reserved for rules not yet taught to report a span, so a consumer counting flagged lines can
  exclude them and name them rather than silently assume 1.

  The range is derived rather than stored because `ClosedRange` traps when constructed with its
  bounds inverted, and storing one would put that trap at every rule site computing a region
  from parsed syntax. Every malformed region — inverted, unanchored, or not 1-based — yields
  `nil` instead.

  Additive: the parameter defaults to `nil`, existing construction sites are unaffected, and
  JSON written before this version decodes with no span.

### Fixed
- The `QualityGateTypes` target no longer excludes `QualityGateTypes.docc` from its source
  files. The exclusion is how swift-docc-plugin fails to find a catalogue: DocC received no
  articles for the target, so their curation and symbol links were never checked and a passing
  `doc-lint` said nothing about them. `doc-lint` now examines the catalogue and reports the
  coverage it examined.

### Changed
- Tests use non-failable UTF-8 conversions (`String(decoding:as:)`, `Data(_:utf8)`) in place of
  force-unwrapped `String(data:encoding:)!` and `.data(using:.utf8)!`, clearing eight
  `safety` force-unwrap errors. No API or behavior change — the package eats its own dog food.

## [1.4.0] - 2026-08-15

### Added
- `Diagnostic.isViolation` — whether a diagnostic asserts a defect (`severity >= .warning`).
  Notes describe what a checker *did* — coverage, skips, environment — and are not violations
  of their rule.

  **This changes every consuming project's score.** Counting was severity-blind: when a checker
  failed, every diagnostic it emitted was counted against its rule, notes included. That gave
  `doc-code.coverage` a violation cluster from 12,844 occurrences that are `note` every single
  time — and which are emitted precisely when the checker *succeeds*, so no repository could
  drive it to zero. Pure-note clusters (`doc-code.coverage` at 1,903, `doc-comment-code.coverage`
  at 9,408) disappear once a pulse regenerates; error-backed clusters do not move at all
  (`doc-generated.region-missing-line` at 633, `exact-double-equality` at 2,149). Existing
  corpus clusters remain wrong until regenerated — a corpus operation, not a code one.

  Consumers must adopt this before their own filters can use it; see
  `ConsistencySeverityAndProvenance.md` in quality-gate-swift for the ordering.

## [1.3.0] - 2026-07-10

### Added
- `Diagnostic.origin` — provenance for non-native findings, e.g. `"plugin/swift-vigil@0.5.0"`
  (quality-gate Phase 4b).

## [1.2.0] - 2026-07-10

### Added
- Tier-2 plugin contract vocabulary (`PluginContract`), for quality-gate Phase 4b.

### Changed
- `legibility:description` on `Package.swift`.

## [1.1.1] - 2026-06-16

### Changed
- Removed the `development-guidelines` submodule from the package.

## [1.1.0] - 2026-06-10

### Added
- `ComplianceRecord` type and `complianceRecords` field on `CheckResult`.

## [1.0.0] - 2026-04-28

### Added
- Deprecated convenience init on `Diagnostic` for backward-compatible parameter labels (`file`/`line`/`column`).

## [0.1.0] - 2025-04-28

### Added
- `CheckResult` — quality check result with status, diagnostics, overrides, and duration.
- `Diagnostic` — individual diagnostic message with severity, location, rule ID, and suggested fix.
- `DiagnosticOverride` — record of a suppressed diagnostic with justification.
- Backward-compatible JSON decoding for legacy `file`/`line`/`column` keys.
