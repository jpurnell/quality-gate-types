import Foundation

/// The result of a quality check execution.
///
/// Each checker returns a `CheckResult` indicating pass/fail status,
/// any diagnostics found, and any overrides (exempted diagnostics).
public struct CheckResult: Sendable, Codable, Equatable {

    /// The status of a quality check.
    public enum Status: String, Sendable, Codable {
        case passed
        case failed
        case warning
        case skipped

        /// Whether this status indicates the check did not fail.
        public var isPassing: Bool {
            switch self {
            case .passed, .warning, .skipped: true
            case .failed: false
            }
        }
    }

    /// The identifier of the checker that produced this result.
    public let checkerId: String
    /// The overall status of the check.
    public let status: Status
    /// Diagnostics (issues) found by this checker.
    public let diagnostics: [Diagnostic]
    /// Diagnostics that were suppressed by exemption comments or configuration.
    public let overrides: [DiagnosticOverride]
    /// How long the check took to execute.
    public let duration: Duration

    /// The count of error-severity diagnostics.
    public var errorCount: Int {
        diagnostics.filter { $0.severity == .error }.count
    }

    /// The count of warning-severity diagnostics.
    public var warningCount: Int {
        diagnostics.filter { $0.severity == .warning }.count
    }

    /// Creates a new check result.
    ///
    /// - Parameters:
    ///   - checkerId: The checker's identifier.
    ///   - status: The check status.
    ///   - diagnostics: Any diagnostics produced.
    ///   - overrides: Diagnostics suppressed by exemptions (defaults to empty).
    ///   - duration: The execution duration.
    public init(
        checkerId: String,
        status: Status,
        diagnostics: [Diagnostic],
        overrides: [DiagnosticOverride] = [],
        duration: Duration
    ) {
        self.checkerId = checkerId
        self.status = status
        self.diagnostics = diagnostics
        self.overrides = overrides
        self.duration = duration
    }
}
