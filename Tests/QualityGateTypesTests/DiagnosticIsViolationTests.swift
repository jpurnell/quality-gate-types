import Testing
import Foundation
@testable import QualityGateTypes

/// Tests for `Diagnostic.isViolation`, the single definition of what counts as a defect.
///
/// It exists because checker-level failure was being used as a proxy for diagnostic-level
/// violation: when a checker failed, every diagnostic it emitted — notes included — was
/// counted as a violation of its rule. The corpus records `doc-code.coverage` as severity
/// `note` in all 12,844 occurrences and it still acquired a violation cluster, because
/// emitting it *is* the success path. No edit to any repository could drive that cluster to
/// zero.
///
/// Both the gate and the Institutional Judgment System filter on this, which is why it lives
/// on the shared type rather than being written twice.
@Suite("Diagnostic.isViolation")
struct DiagnosticIsViolationTests {

    private func diagnostic(_ severity: Diagnostic.Severity, rule: String) -> Diagnostic {
        Diagnostic(severity: severity, message: "m", ruleId: rule)
    }

    @Test("An error is a violation")
    func errorIsViolation() {
        #expect(diagnostic(.error, rule: "exact-double-equality").isViolation)
    }

    @Test("A warning is a violation")
    func warningIsViolation() {
        #expect(diagnostic(.warning, rule: "missing-assertion").isViolation)
    }

    /// The case the whole change is for. A note describes what the checker *did* — coverage,
    /// skips, environment — not what the code got wrong.
    @Test("A note is not a violation")
    func noteIsNotViolation() {
        #expect(!diagnostic(.note, rule: "doc-code.coverage").isViolation)
    }

    /// The rule is severity, never nomenclature. `doc-generated.region-missing-line` reads
    /// note-shaped from its name and is `error` in all 639 recorded occurrences; guessing from
    /// the suffix would drop a real violation, and guessing the other way would keep a
    /// coverage note. Both directions are checked so neither heuristic can creep back in.
    @Test("Severity decides, not the rule's name")
    func nameDoesNotDecide() {
        #expect(diagnostic(.error, rule: "doc-generated.region-missing-line").isViolation)
        #expect(!diagnostic(.note, rule: "doc-code.compile-error").isViolation)
    }

    /// Total over the enum: every case is classified, so a severity added later cannot fall
    /// through into whichever answer the last `if` happened to leave behind.
    @Test("Every severity is classified")
    func totalOverSeverity() {
        let classified: [Diagnostic.Severity: Bool] = [
            .error: true,
            .warning: true,
            .note: false,
        ]
        for (severity, expected) in classified {
            #expect(diagnostic(severity, rule: "r").isViolation == expected)
        }
    }
}
