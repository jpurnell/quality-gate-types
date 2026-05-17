# quality-gate-types

Shared Swift types for the quality-gate ecosystem. This package defines the core result and diagnostic models used by `quality-gate-swift` checkers and the Institutional Judgment System.

## Types

| Type | Purpose |
|------|---------|
| `CheckResult` | The outcome of a single quality check (status, diagnostics, duration) |
| `Diagnostic` | An individual issue found during checking (severity, location, message) |
| `DiagnosticOverride` | A record of a suppressed diagnostic with justification |

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jpurnell/quality-gate-types", from: "0.1.0"),
]
```

Then add `"QualityGateTypes"` as a dependency of your target.

## Requirements

- Swift 6.2+
- macOS 14+

## License

MIT
