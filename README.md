# quality-gate-types

Shared Swift types for the quality-gate ecosystem. This package defines the core result and diagnostic models used by `quality-gate-swift` checkers and the Institutional Judgment System.

## Types

| Type | Purpose |
|------|---------|
| `CheckResult` | The outcome of a single quality check (status, diagnostics, duration) |
| `Diagnostic` | An individual issue found during checking (severity, location, message) |
| `DiagnosticOverride` | A record of a suppressed diagnostic with justification |
| `ComplianceRecord` | A record of compliance against a rule |
| `PluginContract` | Version vocabulary for the Tier-2 plugin contract |
| `PluginDescriptor` | How a plugin identifies itself to the gate |
| `PluginCheckRequest` | A scan request handed to a plugin |

A `Diagnostic` carries two fields worth calling out. `isViolation` is whether it asserts a defect
(`severity >= .warning`) — notes describe what a checker *did*, not what a project got wrong, and
must not be counted against a rule. `origin` records provenance for non-native findings, e.g.
`"plugin/swift-vigil@0.5.0"`.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jpurnell/quality-gate-types", from: "1.5.0"),
]
```

Then add `"QualityGateTypes"` as a dependency of your target.

## Requirements

- Swift 6.2+
- macOS 14+

## License

MIT
