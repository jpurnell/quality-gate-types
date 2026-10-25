# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- **iOS 18 platform declaration.** The package declared only macOS, so SwiftPM built it for iOS 12 and `Duration` failed to compile. Nothing else changed; the library had no macOS-only code.

### Fixed
- `QualityGateLoggingTests` no longer call `setenv("QG_LOG")`. The process environment is shared by tests running in parallel, so one test enabling logging made `silentByDefault` fail under `swift test --parallel`. `QGLogger` has an internal initialiser that takes the environment; the public API is unchanged.

### Removed
- The test of `Diagnostic.file`, `.line` and `.column`, the deprecated aliases of `filePath`, `lineNumber` and `columnNumber`. It was the only caller of them and produced the package's only compiler warnings. The aliases themselves remain.

## [1.7.0] - 2026-09-29

### Added
- **`QualityGateLogging`**, a second library product: `os.Logger`'s surface on platforms that have no `os`.

  Linux CI failed with `cannot find 'Logger' in scope`: 121 files across four packages guard `import os` behind `canImport(os)` and then use `Logger` unguarded, so nothing had ever compiled those paths. The shim provides `Logger`, `OSLogPrivacy` and a privacy-aware interpolation so all of those call sites compile unchanged. It lives here because this is the leaf the other packages already depend on.

  It is compiled on every platform under its own names (`QGLogger`, `QGLogMessage`, `QGLogPrivacy`) and aliased to Apple's spellings only where Apple's are absent, so a macOS developer's build and tests exercise it. It is silent unless `QG_LOG` is set to a non-empty value, which routes messages to stderr.

## [1.6.0] - 2026-09-18

### Added
- **`StringProtocol.lines`**, moved here from `quality-gate-swift`'s `QualityGateCore`.

  It carries no gate or corpus semantics — it splits text into lines — but it had become part
  of the static-analysis package's public surface by accident. `quality-gate-dashboard` was
  reaching it transitively, and the moment that package stopped depending on the gate
  (`SeparatingTheJudgmentLayer.md` §3.2), a Markdown renderer stopped compiling over a string
  helper. Both packages already depend on this one, so this is where it belongs.

  `QualityGateCore` re-exports this module, so every existing call site in `quality-gate-swift`
  is unchanged.

  It is worth keeping rather than inlining, because the three obvious ways to split a string
  into lines are each wrong on a file written on Windows, and each differently: `"a\r\nb"`
  becomes `["a\r\nb"]` under `split(separator: "\n")` (CRLF is a single `Character`, so it
  never matches), `["a\r", "b"]` under `components(separatedBy: "\n")` (which searches by
  scalar), and `["a", "", "b"]` under `components(separatedBy: .newlines)` (which counts both
  scalars). The last is the one people reach for *while fixing* the first two, and it is the
  worst for an auditor: doubling a file's line count shifts every line number it reports.

  Eight tests came with it. A ninth was written and removed the same hour, which is the useful
  part: it asserted what each wrong spelling *returns*, which means calling all three — and
  those three calls are precisely what `safety`'s `newline-split` rule forbids. The gate
  rejected the commit, correctly. A demonstration of banned code is still banned code, the doc
  comment's table already records the three results, and the surviving tests pin the claim that
  matters: whatever the alternatives do, `lines` splits each terminator exactly once.


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
