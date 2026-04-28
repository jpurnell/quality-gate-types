import Testing
import Foundation
@testable import QualityGateTypes

@Suite("CheckResult")
struct CheckResultTests {

    // MARK: - Golden Path

    @Test func goldenPath() {
        let diagnostic = Diagnostic(
            severity: .error,
            message: "Force unwrap detected",
            filePath: "Foo.swift",
            lineNumber: 42,
            ruleId: "force-unwrap"
        )
        let override = DiagnosticOverride(
            ruleId: "force-cast",
            justification: "SAFETY: Known type from Objective-C bridge",
            filePath: "Bar.swift",
            lineNumber: 10
        )
        let result = CheckResult(
            checkerId: "safety",
            status: .failed,
            diagnostics: [diagnostic],
            overrides: [override],
            duration: .seconds(2)
        )

        #expect(result.checkerId == "safety")
        #expect(result.status == .failed)
        #expect(result.diagnostics.count == 1)
        #expect(result.overrides.count == 1)
        #expect(result.duration == .seconds(2))
    }

    // MARK: - Default Overrides

    @Test func overridesDefaultToEmpty() {
        let result = CheckResult(
            checkerId: "safety",
            status: .passed,
            diagnostics: [],
            duration: .seconds(1)
        )

        #expect(result.overrides.isEmpty)
    }

    // MARK: - Status

    @Test func statusIsPassing() {
        #expect(CheckResult.Status.passed.isPassing == true)
        #expect(CheckResult.Status.warning.isPassing == true)
        #expect(CheckResult.Status.skipped.isPassing == true)
        #expect(CheckResult.Status.failed.isPassing == false)
    }

    @Test func statusRawValues() {
        #expect(CheckResult.Status.passed.rawValue == "passed")
        #expect(CheckResult.Status.failed.rawValue == "failed")
        #expect(CheckResult.Status.warning.rawValue == "warning")
        #expect(CheckResult.Status.skipped.rawValue == "skipped")
    }

    // MARK: - Computed Counts

    @Test func errorCount() {
        let result = CheckResult(
            checkerId: "safety",
            status: .failed,
            diagnostics: [
                Diagnostic(severity: .error, message: "Error 1"),
                Diagnostic(severity: .warning, message: "Warning 1"),
                Diagnostic(severity: .error, message: "Error 2"),
                Diagnostic(severity: .note, message: "Note 1"),
            ],
            duration: .seconds(1)
        )

        #expect(result.errorCount == 2)
    }

    @Test func warningCount() {
        let result = CheckResult(
            checkerId: "safety",
            status: .warning,
            diagnostics: [
                Diagnostic(severity: .warning, message: "Warning 1"),
                Diagnostic(severity: .warning, message: "Warning 2"),
                Diagnostic(severity: .error, message: "Error 1"),
            ],
            duration: .seconds(1)
        )

        #expect(result.warningCount == 2)
    }

    @Test func countsWithEmptyDiagnostics() {
        let result = CheckResult(
            checkerId: "safety",
            status: .passed,
            diagnostics: [],
            duration: .seconds(0)
        )

        #expect(result.errorCount == 0)
        #expect(result.warningCount == 0)
    }

    // MARK: - Codable Round-Trip

    @Test func codableRoundTrip() throws {
        let original = CheckResult(
            checkerId: "concurrency",
            status: .failed,
            diagnostics: [
                Diagnostic(
                    severity: .error,
                    message: "@unchecked Sendable without justification",
                    filePath: "Worker.swift",
                    lineNumber: 87,
                    ruleId: "unchecked-sendable"
                )
            ],
            overrides: [
                DiagnosticOverride(
                    ruleId: "nonisolated-unsafe",
                    justification: "Justification: Immutable after init",
                    filePath: "Config.swift",
                    lineNumber: 12
                )
            ],
            duration: .seconds(3)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(CheckResult.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - camelCase Keys

    @Test func camelCaseKeys() throws {
        let result = CheckResult(
            checkerId: "safety",
            status: .passed,
            diagnostics: [],
            overrides: [
                DiagnosticOverride(ruleId: "test", justification: "test")
            ],
            duration: .seconds(1)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(result)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"checkerId\""))
        #expect(json.contains("\"diagnostics\""))
        #expect(json.contains("\"overrides\""))
        #expect(json.contains("\"duration\""))
    }

    // MARK: - Status Codable

    @Test func statusCodableRoundTrip() throws {
        for status in [CheckResult.Status.passed, .failed, .warning, .skipped] {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(CheckResult.Status.self, from: data)
            #expect(decoded == status)
        }
    }

    // MARK: - Multiple Overrides

    @Test func multipleOverridesPreserveOrder() {
        let overrides = [
            DiagnosticOverride(ruleId: "rule-a", justification: "first"),
            DiagnosticOverride(ruleId: "rule-b", justification: "second"),
            DiagnosticOverride(ruleId: "rule-c", justification: "third"),
        ]
        let result = CheckResult(
            checkerId: "safety",
            status: .passed,
            diagnostics: [],
            overrides: overrides,
            duration: .seconds(1)
        )

        #expect(result.overrides.count == 3)
        #expect(result.overrides[0].ruleId == "rule-a")
        #expect(result.overrides[1].ruleId == "rule-b")
        #expect(result.overrides[2].ruleId == "rule-c")
    }

    // MARK: - Equatable

    @Test func equalResultsAreEqual() {
        let a = CheckResult(checkerId: "test", status: .passed, diagnostics: [], duration: .seconds(1))
        let b = CheckResult(checkerId: "test", status: .passed, diagnostics: [], duration: .seconds(1))
        #expect(a == b)
    }

    @Test func differentResultsAreNotEqual() {
        let a = CheckResult(checkerId: "test", status: .passed, diagnostics: [], duration: .seconds(1))
        let b = CheckResult(checkerId: "test", status: .failed, diagnostics: [], duration: .seconds(1))
        #expect(a != b)
    }
}
