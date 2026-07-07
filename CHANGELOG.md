# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
