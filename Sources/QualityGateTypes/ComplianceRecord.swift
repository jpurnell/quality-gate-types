import Foundation

/// A record that a compliance annotation was found and verified.
///
/// Unlike ``DiagnosticOverride`` (which represents a suppressed violation),
/// a `ComplianceRecord` confirms that the code meets the auditor's
/// requirements through an inline annotation or configuration entry.
/// No violation occurred — the annotation is the auditor's own required
/// compliance mechanism.
///
/// Examples:
/// - `// Justification:` on `@unchecked Sendable` (concurrency auditor)
/// - Config-allowlisted function in `withUnsafe*` block (pointer escape auditor)
public struct ComplianceRecord: Sendable, Codable, Equatable {
    /// The rule that was checked and found compliant.
    public let ruleId: String
    /// The annotation text or config entry that proves compliance.
    public let annotation: String
    /// Absolute path to the source file where the annotation was found.
    public let filePath: String?
    /// 1-based line number of the annotation.
    public let lineNumber: Int?

    /// Creates a new compliance record.
    ///
    /// - Parameters:
    ///   - ruleId: The rule that was checked.
    ///   - annotation: The text proving compliance.
    ///   - filePath: The file path (optional).
    ///   - lineNumber: The line number (optional).
    public init(
        ruleId: String,
        annotation: String,
        filePath: String? = nil,
        lineNumber: Int? = nil
    ) {
        self.ruleId = ruleId
        self.annotation = annotation
        self.filePath = filePath
        self.lineNumber = lineNumber
    }
}
