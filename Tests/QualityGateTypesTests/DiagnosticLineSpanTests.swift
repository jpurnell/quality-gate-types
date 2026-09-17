import Testing
import Foundation
@testable import QualityGateTypes

/// Tests for `Diagnostic.endLine` and the `lineSpan` derived from it.
///
/// A diagnostic has always carried a point — `lineNumber` — and that is not enough to answer
/// "how many lines did this rule flag?". The question matters because the shape metrics
/// (`plans/proposals/ARatioNeedsAPopulation.md`) compute a *ratio* of flagged lines to SLOC,
/// and a point forces an arbitrary answer: count a `function-body-length` finding over a
/// 40-line body as one line and the ratio collapses into a near-pure function of clone lines;
/// count it as forty and the ratio becomes a function of the long-declaration rules. Either
/// way the number is an artifact of an unstated choice.
///
/// ## Why `endLine`, and not `lineSpan: ClosedRange<Int>?` stored directly
///
/// `ClosedRange` traps on construction when the lower bound exceeds the upper, so storing one
/// would put a `5...3` trap hazard at every rule site that computes a span from parsed syntax —
/// in a project whose coding rules forbid `fatalError` and `precondition` in production code.
/// Storing the end line and *deriving* the range moves the failure from a trap to a `nil`.
///
/// ## Why `nil` means "did not say", not "one line"
///
/// A rule that has no meaningful span declares `endLine == lineNumber` explicitly. Absence is
/// reserved for "this rule has not been taught to report a span", so the metrics pass can
/// exclude it and name it in its coverage note rather than silently assuming 1. Examined
/// nothing must not look like found nothing.
@Suite("Diagnostic.lineSpan")
struct DiagnosticLineSpanTests {

    private func diagnostic(line: Int?, endLine: Int?) -> Diagnostic {
        Diagnostic(
            severity: .note,
            message: "m",
            filePath: "/tmp/F.swift",
            lineNumber: line,
            ruleId: "shape.fixture",
            endLine: endLine
        )
    }

    // MARK: - Absence is not one line

    @Test("A rule that declares no end line has no span")
    func noEndLineMeansNoSpan() {
        let subject = diagnostic(line: 12, endLine: nil)
        #expect(subject.lineSpan == nil)
        #expect(subject.lineCount == nil)
    }

    @Test("A single-line rule declares its span explicitly and spans one line")
    func explicitSingleLineSpan() {
        let subject = diagnostic(line: 12, endLine: 12)
        #expect(subject.lineSpan == 12...12)
        #expect(subject.lineCount == 1)
    }

    @Test("A multi-line span counts every line it covers, both ends included")
    func multiLineSpanIsInclusive() {
        let subject = diagnostic(line: 10, endLine: 49)
        #expect(subject.lineSpan == 10...49)
        #expect(subject.lineCount == 40)
    }

    // MARK: - Malformed spans degrade to nil rather than trapping

    @Test("An inverted span yields no span instead of trapping")
    func invertedSpanIsNil() {
        let subject = diagnostic(line: 20, endLine: 5)
        #expect(subject.lineSpan == nil)
        #expect(subject.lineCount == nil)
    }

    @Test("An end line without a start line yields no span")
    func endLineWithoutStartIsNil() {
        #expect(diagnostic(line: nil, endLine: 40).lineSpan == nil)
    }

    @Test("Line numbers are 1-based, so a zero or negative start yields no span")
    func nonPositiveStartIsNil() {
        #expect(diagnostic(line: 0, endLine: 10).lineSpan == nil)
        #expect(diagnostic(line: -3, endLine: 10).lineSpan == nil)
    }

    // MARK: - Codable

    @Test("A span survives a Codable round trip")
    func spanRoundTrips() throws {
        let subject = diagnostic(line: 10, endLine: 49)
        let data = try JSONEncoder().encode(subject)
        let decoded = try JSONDecoder().decode(Diagnostic.self, from: data)
        #expect(decoded.endLine == 49)
        #expect(decoded.lineSpan == 10...49)
        #expect(decoded == subject)
    }

    @Test("Legacy JSON without an end line decodes to no span")
    func legacyJSONHasNoSpan() throws {
        let json = #"{"severity":"note","message":"m","filePath":"/tmp/F.swift","lineNumber":12}"#
        guard let data = json.data(using: .utf8) else {
            Issue.record("fixture JSON is not valid UTF-8")
            return
        }
        let decoded = try JSONDecoder().decode(Diagnostic.self, from: data)
        #expect(decoded.endLine == nil)
        #expect(decoded.lineSpan == nil)
    }

    @Test("A diagnostic with no end line does not emit the key")
    func absentEndLineIsOmittedFromJSON() throws {
        let data = try JSONEncoder().encode(diagnostic(line: 12, endLine: nil))
        guard let json = String(data: data, encoding: .utf8) else {
            Issue.record("encoded diagnostic is not valid UTF-8")
            return
        }
        #expect(!json.contains("endLine"))
    }

    // MARK: - Identity

    @Test("Two diagnostics differing only in their end line are not equal")
    func endLineParticipatesInEquality() {
        #expect(diagnostic(line: 10, endLine: 49) != diagnostic(line: 10, endLine: 12))
        #expect(diagnostic(line: 10, endLine: 49) != diagnostic(line: 10, endLine: nil))
    }

    @Test("Existing construction sites keep compiling and report no span")
    func endLineDefaultsToAbsent() {
        let subject = Diagnostic(severity: .warning, message: "m", filePath: "/tmp/F.swift", lineNumber: 3)
        #expect(subject.endLine == nil)
        #expect(subject.lineSpan == nil)
    }
}
