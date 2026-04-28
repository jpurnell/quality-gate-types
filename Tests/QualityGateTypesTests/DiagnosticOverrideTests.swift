import Testing
import Foundation
@testable import QualityGateTypes

@Suite("DiagnosticOverride")
struct DiagnosticOverrideTests {

    // MARK: - Golden Path

    @Test func goldenPath() {
        let override = DiagnosticOverride(
            ruleId: "force-unwrap",
            justification: "SAFETY: C-API interop requires force unwrap — nil case unreachable per API contract",
            filePath: "Sources/Interop/Bridge.swift",
            lineNumber: 42
        )

        #expect(override.ruleId == "force-unwrap")
        #expect(override.justification.contains("C-API interop"))
        #expect(override.filePath == "Sources/Interop/Bridge.swift")
        #expect(override.lineNumber == 42)
    }

    // MARK: - Codable Round-Trip

    @Test func codableRoundTrip() throws {
        let original = DiagnosticOverride(
            ruleId: "unchecked-sendable",
            justification: "Justification: Thread-safe via internal lock",
            filePath: "Sources/Pipeline/Worker.swift",
            lineNumber: 87
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DiagnosticOverride.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - camelCase Keys

    @Test func camelCaseKeys() throws {
        let override = DiagnosticOverride(
            ruleId: "force-unwrap",
            justification: "SAFETY: test",
            filePath: "Foo.swift",
            lineNumber: 10
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(override)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"ruleId\""))
        #expect(json.contains("\"justification\""))
        #expect(json.contains("\"filePath\""))
        #expect(json.contains("\"lineNumber\""))
    }

    // MARK: - Nil Optionals

    @Test func nilOptionalsForConfigBasedOverride() throws {
        let override = DiagnosticOverride(
            ruleId: "pointer-escape",
            justification: "Allowed by configuration: vDSP_fft_zip"
        )

        #expect(override.filePath == nil)
        #expect(override.lineNumber == nil)

        let data = try JSONEncoder().encode(override)
        let json = String(data: data, encoding: .utf8)!

        #expect(!json.contains("filePath"))
        #expect(!json.contains("lineNumber"))
    }

    // MARK: - Equatable

    @Test func equalOverridesAreEqual() {
        let a = DiagnosticOverride(ruleId: "test", justification: "reason")
        let b = DiagnosticOverride(ruleId: "test", justification: "reason")
        #expect(a == b)
    }

    @Test func differentOverridesAreNotEqual() {
        let a = DiagnosticOverride(ruleId: "test", justification: "reason A")
        let b = DiagnosticOverride(ruleId: "test", justification: "reason B")
        #expect(a != b)
    }
}
