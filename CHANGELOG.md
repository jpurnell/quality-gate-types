# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
