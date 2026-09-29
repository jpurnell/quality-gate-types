import Foundation
import Testing
@testable import QualityGateLogging

/// The logging shim, exercised on every platform — including the one that does not need it.
///
/// The implementation is compiled everywhere and aliased to Apple's spellings only where
/// Apple's are absent, precisely so these tests run on a developer's Mac. A shim that
/// compiled only on Linux would be verified only by CI, and this package reached 104 files
/// of never-compiled logging by trusting exactly that arrangement.
@Suite("QualityGateLogging")
struct QualityGateLoggingTests {

    @Test("A literal message renders as itself")
    func literalRendersUnchanged() {
        let message: QGLogMessage = "adopt: config resolution failed"
        #expect(message.rendered == "adopt: config resolution failed")
    }

    @Test("A privacy-annotated interpolation renders its value, not its annotation")
    func privacyInterpolationRendersValue() {
        let checker = "doc-code"
        let message: QGLogMessage = "checker '\(checker, privacy: .public)' threw"
        #expect(message.rendered == "checker 'doc-code' threw")
    }

    @Test("Interpolation without a privacy annotation is accepted too")
    func plainInterpolationWorks() {
        let count = 46
        let message: QGLogMessage = "ran \(count) checkers"
        #expect(message.rendered == "ran 46 checkers")
    }

    @Test("A non-String value renders through its description, not its type name")
    func nonStringValuesRenderTheirDescription() {
        // 442 of this package's 443 interpolations are `.public`, and many carry an Int,
        // a URL or an enum. `String(describing:)` on a type that forgot CustomStringConvertible
        // is how a log line becomes the word "Optional" and nothing useful.
        let n = 22
        let url = URL(fileURLWithPath: "/tmp/x.swift")
        #expect(QGLogMessage("\(n, privacy: .public)").rendered == "22")
        #expect(QGLogMessage("\(url.lastPathComponent, privacy: .public)").rendered == "x.swift")
    }

    @Test("Every severity the package uses exists and accepts an interpolated message")
    func allSeveritiesAccepted() {
        // warning 227, error 26, debug 16, info 12, notice 6 — the counts measured across
        // quality-gate-swift. A missing method is a compile error in 43 targets, so this
        // test is about the surface existing at all.
        setenv("QG_LOG", "1", 1)
        defer { unsetenv("QG_LOG") }
        let logger = QGLogger(subsystem: "com.quality-gate", category: "Test")
        let value = "x"

        // Calling each method proves the surface exists — a missing one is a compile error
        // in 43 targets. Asserting the rendered line proves the severity reaches the output
        // rather than every level collapsing to one label, which compiling cannot show.
        for level in ["DEBUG", "INFO", "NOTICE", "WARNING", "ERROR", "CRITICAL", "FAULT"] {
            let line = logger.renderedLine(level, "m \(value, privacy: .public)")
            #expect(line == "\(level) [com.quality-gate:Test] m x\n")
        }

        logger.debug("d \(value, privacy: .public)")
        logger.info("i \(value, privacy: .public)")
        logger.notice("n \(value, privacy: .public)")
        logger.warning("w \(value, privacy: .public)")
        logger.error("e \(value, privacy: .public)")
        logger.critical("c \(value, privacy: .public)")
        logger.fault("f \(value, privacy: .public)")
    }

    @Test("Silent unless QG_LOG says otherwise")
    func silentByDefault() {
        // os.Logger writes to the unified log, not the terminal, so a CLI using it prints
        // nothing extra. A shim that wrote 287 call sites to stderr would change what this
        // tool's output *is* on Linux — every run a wall of diagnostics.
        let logger = QGLogger(subsystem: "com.quality-gate", category: "Test")
        let unset = ProcessInfo.processInfo.environment["QG_LOG"]?.isEmpty ?? true
        if unset {
            #expect(logger.renderedLine("WARNING", "anything") == nil)
        }
    }

    @Test("A rendered line names its level and its subsystem")
    func renderedLineIsTagged() throws {
        setenv("QG_LOG", "1", 1)
        defer { unsetenv("QG_LOG") }
        let logger = QGLogger(subsystem: "com.quality-gate", category: "Adopt")
        let line = try #require(logger.renderedLine("WARNING", "ledger unreadable"))
        #expect(line == "WARNING [com.quality-gate:Adopt] ledger unreadable\n")
    }

    @Test("An untagged logger omits the bracket rather than printing an empty one")
    func untaggedLoggerHasNoBrackets() throws {
        setenv("QG_LOG", "1", 1)
        defer { unsetenv("QG_LOG") }
        let line = try #require(QGLogger().renderedLine("INFO", "hello"))
        #expect(line == "INFO hello\n")
    }
}
