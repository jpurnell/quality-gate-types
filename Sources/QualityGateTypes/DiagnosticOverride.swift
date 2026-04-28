import Foundation

/// A record of a diagnostic that was suppressed by an exemption.
///
/// Created by quality gate checkers when an exemption comment (e.g., `// SAFETY:`)
/// or configuration allowlist causes a diagnostic to be suppressed. Captures the
/// context of the override so it can be tracked for institutional learning.
public struct DiagnosticOverride: Sendable, Codable, Equatable {
    /// The rule that would have triggered a diagnostic.
    public let ruleId: String
    /// The exemption text that suppressed the diagnostic (comment text or config entry).
    public let justification: String
    /// Absolute path to the source file where the override occurred.
    public let filePath: String?
    /// 1-based line number where the override occurred.
    public let lineNumber: Int?

    /// Creates a new diagnostic override record.
    ///
    /// - Parameters:
    ///   - ruleId: The rule that would have triggered a diagnostic.
    ///   - justification: The exemption text.
    ///   - filePath: The file path (optional, nil for config-based overrides).
    ///   - lineNumber: The line number (optional).
    public init(
        ruleId: String,
        justification: String,
        filePath: String? = nil,
        lineNumber: Int? = nil
    ) {
        self.ruleId = ruleId
        self.justification = justification
        self.filePath = filePath
        self.lineNumber = lineNumber
    }
}
