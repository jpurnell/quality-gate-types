import Foundation

/// A single diagnostic message from a quality check.
///
/// Represents individual issues found during quality checking: compile errors,
/// safety violations, concurrency warnings, and similar. This is the shared
/// type used by both quality-gate-swift and the Institutional Judgment System.
public struct Diagnostic: Sendable, Equatable {

    /// The severity level of the diagnostic.
    public enum Severity: String, Sendable, Codable, Comparable {
        case error
        case warning
        case note
		
		/// A comparison operator for Severity.
        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            let order: [Severity] = [.note, .warning, .error]
            guard let lhsIndex = order.firstIndex(of: lhs),
                  let rhsIndex = order.firstIndex(of: rhs) else {
                return false
            }
            return lhsIndex < rhsIndex
        }
    }

    /// The severity of this diagnostic.
    public let severity: Severity
    /// Human-readable description of the issue.
    public let message: String
    /// Absolute path to the source file where the issue was found.
    public let filePath: String?
    /// 1-based line number where the issue was detected.
    public let lineNumber: Int?
    /// 1-based column number where the issue was detected.
    public let columnNumber: Int?
    /// Identifier for the rule that triggered this diagnostic.
    public let ruleId: String?
    /// A suggested fix for the issue, if available.
    public let suggestedFix: String?

    /// Whether a suggested fix is available for this diagnostic.
    public var isFixable: Bool { suggestedFix != nil }

	/// Absolute path to the source file where the issue was found.
    @available(*, deprecated, renamed: "filePath")
    public var file: String? { filePath }

	/// 1-based line number where the issue was detected.
    @available(*, deprecated, renamed: "lineNumber")
    public var line: Int? { lineNumber }
	
	/// 1-based column number where the issue was detected.
    @available(*, deprecated, renamed: "columnNumber")
    public var column: Int? { columnNumber }

    /// Creates a new diagnostic.
    ///
    /// - Parameters:
    ///   - severity: The severity level.
    ///   - message: The diagnostic message.
    ///   - filePath: The file path (optional).
    ///   - lineNumber: The line number (optional).
    ///   - columnNumber: The column number (optional).
    ///   - ruleId: The rule identifier (optional).
    ///   - suggestedFix: A suggested fix (optional).
    public init(
        severity: Severity,
        message: String,
        filePath: String? = nil,
        lineNumber: Int? = nil,
        columnNumber: Int? = nil,
        ruleId: String? = nil,
        suggestedFix: String? = nil
    ) {
        self.severity = severity
        self.message = message
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.columnNumber = columnNumber
        self.ruleId = ruleId
        self.suggestedFix = suggestedFix
    }

    /// Backward-compatible initializer using legacy parameter names.
    @available(*, deprecated, message: "Use init(severity:message:filePath:lineNumber:columnNumber:ruleId:suggestedFix:)")
    public init(
        severity: Severity,
        message: String,
        file: String?,
        line: Int? = nil,
        column: Int? = nil,
        ruleId: String? = nil,
        suggestedFix: String? = nil
    ) {
        self.init(
            severity: severity,
            message: message,
            filePath: file,
            lineNumber: line,
            columnNumber: column,
            ruleId: ruleId,
            suggestedFix: suggestedFix
        )
    }
}

// MARK: - Codable (backward-compatible JSON decoding)

extension Diagnostic: Codable {

    private enum CodingKeys: String, CodingKey {
        case severity, message, ruleId, suggestedFix
        case filePath, lineNumber, columnNumber
        case file, line, column
    }
	
	/// Creates a new diagnostic from a Decoder.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        severity = try container.decode(Severity.self, forKey: .severity)
        message = try container.decode(String.self, forKey: .message)
        filePath = try container.decodeIfPresent(String.self, forKey: .filePath)
                ?? container.decodeIfPresent(String.self, forKey: .file)
        lineNumber = try container.decodeIfPresent(Int.self, forKey: .lineNumber)
                  ?? container.decodeIfPresent(Int.self, forKey: .line)
        columnNumber = try container.decodeIfPresent(Int.self, forKey: .columnNumber)
                    ?? container.decodeIfPresent(Int.self, forKey: .column)
        ruleId = try container.decodeIfPresent(String.self, forKey: .ruleId)
        suggestedFix = try container.decodeIfPresent(String.self, forKey: .suggestedFix)
    }
	/// Encodes a new diagnostic
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(severity, forKey: .severity)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(filePath, forKey: .filePath)
        try container.encodeIfPresent(lineNumber, forKey: .lineNumber)
        try container.encodeIfPresent(columnNumber, forKey: .columnNumber)
        try container.encodeIfPresent(ruleId, forKey: .ruleId)
        try container.encodeIfPresent(suggestedFix, forKey: .suggestedFix)
    }
}
