# ``QualityGateTypes``

The vocabulary quality-gate-swift and the Institutional Judgment System share.

## Overview

This package holds the types that cross a boundary between two systems, and nothing else. A
checker in quality-gate-swift produces a ``CheckResult``; the Institutional Judgment System
reads that same result out of persisted telemetry, weeks later, to build a pulse. Both must
agree on what a diagnostic is, what severities exist, and — as of 1.4.0 — which diagnostics
assert a defect.

That last point is why definitions like ``Diagnostic/isViolation`` live here rather than in
either consumer. When the two systems each counted violations for themselves, they counted
differently: notes were treated as violations of their rule, so `doc-code.coverage` — emitted
on the success path, severity `note` in all 12,844 recorded occurrences — accumulated a
violation cluster that no repository could drive to zero. One definition on the shared type is
the structural fix; agreeing twice is what failed.

Types here are `Sendable` and `Codable`, because they cross both concurrency domains and
process boundaries. `Codable` conformance is deliberately backward-compatible: ``Diagnostic``
decodes the legacy `file` / `line` / `column` keys alongside the current
`filePath` / `lineNumber` / `columnNumber`, so telemetry written by older gates stays readable.
A corpus that cannot read its own history is not a corpus.

## Topics

### Results

- ``CheckResult``
- ``ComplianceRecord``

### Diagnostics

- ``Diagnostic``
- ``DiagnosticOverride``

### Plugins

- ``PluginContract``
