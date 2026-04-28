import Testing
import Foundation
@testable import QualityGateTypes

@Suite("Diagnostic")
struct DiagnosticTests {

    // MARK: - Golden Path

    @Test func goldenPath() {
        let diagnostic = Diagnostic(
            severity: .error,
            message: "Force unwrap detected",
            filePath: "Sources/Math/Division.swift",
            lineNumber: 42,
            columnNumber: 15,
            ruleId: "force-unwrap",
            suggestedFix: "Use optional binding instead"
        )

        #expect(diagnostic.severity == .error)
        #expect(diagnostic.message == "Force unwrap detected")
        #expect(diagnostic.filePath == "Sources/Math/Division.swift")
        #expect(diagnostic.lineNumber == 42)
        #expect(diagnostic.columnNumber == 15)
        #expect(diagnostic.ruleId == "force-unwrap")
        #expect(diagnostic.suggestedFix == "Use optional binding instead")
    }

    // MARK: - isFixable

    @Test func isFixableWhenSuggestedFixPresent() {
        let diagnostic = Diagnostic(
            severity: .error,
            message: "Force unwrap",
            suggestedFix: "Use binding"
        )
        #expect(diagnostic.isFixable == true)
    }

    @Test func isFixableWhenSuggestedFixNil() {
        let diagnostic = Diagnostic(
            severity: .warning,
            message: "Unused variable"
        )
        #expect(diagnostic.isFixable == false)
    }

    // MARK: - Severity Comparison

    @Test func severityOrdering() {
        #expect(Diagnostic.Severity.note < .warning)
        #expect(Diagnostic.Severity.warning < .error)
        #expect(Diagnostic.Severity.note < .error)
        #expect(!(Diagnostic.Severity.error < .error))
        #expect(!(Diagnostic.Severity.error < .warning))
    }

    // MARK: - Codable Round-Trip

    @Test func codableRoundTrip() throws {
        let original = Diagnostic(
            severity: .error,
            message: "Force unwrap detected",
            filePath: "Sources/Math/Division.swift",
            lineNumber: 42,
            columnNumber: 15,
            ruleId: "force-unwrap",
            suggestedFix: "Use optional binding"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(Diagnostic.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Canonical JSON Keys

    @Test func encodesCanonicalCamelCaseKeys() throws {
        let diagnostic = Diagnostic(
            severity: .error,
            message: "test",
            filePath: "Foo.swift",
            lineNumber: 10,
            columnNumber: 5,
            ruleId: "test-rule",
            suggestedFix: "fix it"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(diagnostic)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"filePath\""))
        #expect(json.contains("\"lineNumber\""))
        #expect(json.contains("\"columnNumber\""))
        #expect(json.contains("\"ruleId\""))
        #expect(json.contains("\"suggestedFix\""))
        #expect(!json.contains("\"file\""))
        #expect(!json.contains("\"line\""))
        #expect(!json.contains("\"column\""))
    }

    // MARK: - Legacy JSON Decoding

    @Test func decodesLegacyKeys() throws {
        let legacyJSON = """
        {
            "severity": "error",
            "message": "Force unwrap detected",
            "file": "Foo.swift",
            "line": 42,
            "column": 15,
            "ruleId": "force-unwrap",
            "suggestedFix": "Use binding"
        }
        """.data(using: .utf8)!

        let diagnostic = try JSONDecoder().decode(Diagnostic.self, from: legacyJSON)

        #expect(diagnostic.filePath == "Foo.swift")
        #expect(diagnostic.lineNumber == 42)
        #expect(diagnostic.columnNumber == 15)
    }

    @Test func decodesMixedKeys() throws {
        let mixedJSON = """
        {
            "severity": "warning",
            "message": "test",
            "filePath": "Bar.swift",
            "line": 99
        }
        """.data(using: .utf8)!

        let diagnostic = try JSONDecoder().decode(Diagnostic.self, from: mixedJSON)

        #expect(diagnostic.filePath == "Bar.swift")
        #expect(diagnostic.lineNumber == 99)
        #expect(diagnostic.columnNumber == nil)
    }

    @Test func canonicalKeysTakePrecedenceOverLegacy() throws {
        let bothJSON = """
        {
            "severity": "error",
            "message": "test",
            "filePath": "Canonical.swift",
            "file": "Legacy.swift",
            "lineNumber": 100,
            "line": 200
        }
        """.data(using: .utf8)!

        let diagnostic = try JSONDecoder().decode(Diagnostic.self, from: bothJSON)

        #expect(diagnostic.filePath == "Canonical.swift")
        #expect(diagnostic.lineNumber == 100)
    }

    // MARK: - Deprecated Aliases

    @Test func deprecatedAliasesReturnSameValues() {
        let diagnostic = Diagnostic(
            severity: .error,
            message: "test",
            filePath: "Foo.swift",
            lineNumber: 42,
            columnNumber: 15
        )

        #expect(diagnostic.file == diagnostic.filePath)
        #expect(diagnostic.line == diagnostic.lineNumber)
        #expect(diagnostic.column == diagnostic.columnNumber)
    }

    // MARK: - Nil Optionals

    @Test func nilOptionalsEncodedCorrectly() throws {
        let diagnostic = Diagnostic(severity: .note, message: "Info only")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(diagnostic)
        let json = String(data: data, encoding: .utf8)!

        #expect(!json.contains("filePath"))
        #expect(!json.contains("lineNumber"))
        #expect(!json.contains("columnNumber"))
        #expect(!json.contains("ruleId"))
        #expect(!json.contains("suggestedFix"))
    }

    // MARK: - Equatable

    @Test func equalDiagnosticsAreEqual() {
        let a = Diagnostic(severity: .error, message: "test", filePath: "A.swift", lineNumber: 1)
        let b = Diagnostic(severity: .error, message: "test", filePath: "A.swift", lineNumber: 1)
        #expect(a == b)
    }

    @Test func differentDiagnosticsAreNotEqual() {
        let a = Diagnostic(severity: .error, message: "test", filePath: "A.swift", lineNumber: 1)
        let b = Diagnostic(severity: .warning, message: "test", filePath: "A.swift", lineNumber: 1)
        #expect(a != b)
    }

    // MARK: - Severity Codable

    @Test func severityCodableRoundTrip() throws {
        for severity in [Diagnostic.Severity.error, .warning, .note] {
            let data = try JSONEncoder().encode(severity)
            let decoded = try JSONDecoder().decode(Diagnostic.Severity.self, from: data)
            #expect(decoded == severity)
        }
    }

    @Test func severityRawValues() {
        #expect(Diagnostic.Severity.error.rawValue == "error")
        #expect(Diagnostic.Severity.warning.rawValue == "warning")
        #expect(Diagnostic.Severity.note.rawValue == "note")
    }
}
