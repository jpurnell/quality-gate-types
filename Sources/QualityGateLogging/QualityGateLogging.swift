#if canImport(os)
@_exported import os
#endif

import Foundation

// The shim's types are compiled on EVERY platform, under their own names, and only
// aliased to Apple's spellings where Apple's are absent. The alternative — defining
// `Logger` inside `#if !canImport(os)` — would mean the Linux implementation is never
// compiled by any build a macOS developer can run, and never exercised by any test they
// can execute. A port whose code only compiles on the machine that cannot check it is
// how this package arrived at 104 files of never-compiled logging in the first place.

/// The privacy annotation `os.Logger` interpolation accepts.
///
/// Carried so call sites written for Apple's logger compile unchanged. The value is not
/// consulted: redaction on a platform with no unified log would mean withholding text from
/// a developer reading their own terminal, which protects nobody.
public struct QGLogPrivacy: Sendable, Equatable {
    private let name: String
    /// Rendered in full.
    public static let `public` = QGLogPrivacy(name: "public")
    /// Rendered in full here; see the type's note on why.
    public static let `private` = QGLogPrivacy(name: "private")
    /// Rendered in full here; see the type's note on why.
    public static let auto = QGLogPrivacy(name: "auto")
    private init(name: String) { self.name = name }
}

/// A log message assembled from a string literal and its interpolations.
public struct QGLogMessage: ExpressibleByStringLiteral, ExpressibleByStringInterpolation, Sendable {
    /// The fully rendered text.
    public let rendered: String

    /// Creates a message from a literal with no interpolations.
    /// - Parameter value: The literal text.
    public init(stringLiteral value: String) { rendered = value }
    /// Creates a message from an interpolated literal.
    /// - Parameter stringInterpolation: The accumulated segments.
    public init(stringInterpolation: StringInterpolation) { rendered = stringInterpolation.text }

    /// Accepts the shapes `os.Logger` accepts, so no call site changes.
    public struct StringInterpolation: StringInterpolationProtocol, Sendable {
        var text: String

        /// Creates the accumulator the compiler fills segment by segment.
        /// - Parameters:
        ///   - literalCapacity: Total length of the literal segments.
        ///   - interpolationCount: How many interpolations follow.
        public init(literalCapacity: Int, interpolationCount: Int) {
            text = ""
            text.reserveCapacity(literalCapacity + interpolationCount * 8)
        }

        /// Appends a literal segment.
        /// - Parameter literal: The text between interpolations.
        public mutating func appendLiteral(_ literal: String) { text += literal }

        /// `\(value)` and `\(value, privacy: .public)` alike.
        ///
        /// `Any` rather than a generic with overloads: every interpolation in this package
        /// is a value rendered into a diagnostic, and one entry point cannot become
        /// ambiguous the way a set of overloads can.
        public mutating func appendInterpolation(_ value: Any, privacy: QGLogPrivacy = .public) {
            if let text = value as? String {
                self.text += text
            } else if let convertible = value as? any CustomStringConvertible {
                self.text += convertible.description
            } else {
                self.text += String(describing: value)
            }
        }
    }
}

/// A logger with `os.Logger`'s surface, for platforms without the unified log.
///
/// **Silent unless asked.** `os.Logger` writes to the unified log, not to the terminal, so a
/// CLI using it prints nothing extra. A shim that wrote 287 call sites to stderr would turn
/// every Linux run into a wall of diagnostics and change what the tool's output *is*. Set
/// `QG_LOG` to a non-empty value to route messages to stderr, which is where diagnostics
/// belong when they are wanted at all.
public struct QGLogger: Sendable {
    private let subsystem: String
    private let category: String
    private let environment: @Sendable () -> [String: String]

    /// Creates a logger tagged with a subsystem and category, as Apple's is.
    public init(subsystem: String, category: String) {
        self.init(subsystem: subsystem, category: category) { ProcessInfo.processInfo.environment }
    }

    /// Creates a logger that reads `QG_LOG` from `environment` instead of the process.
    ///
    /// Tests use this so they never call `setenv`: the process environment is shared by every
    /// test running in parallel, and a test that sets `QG_LOG` makes a neighbour that expects
    /// silence fail.
    init(subsystem: String, category: String, environment: @escaping @Sendable () -> [String: String]) {
        self.subsystem = subsystem
        self.category = category
        self.environment = environment
    }

    /// Creates an untagged logger.
    public init() {
        self.init(subsystem: "", category: "")
    }

    /// Logs at debug severity.
    /// - Parameter message: The message to record.
    public func debug(_ message: QGLogMessage) { emit("DEBUG", message) }

    /// Logs at info severity.
    /// - Parameter message: The message to record.
    public func info(_ message: QGLogMessage) { emit("INFO", message) }

    /// Logs at notice severity.
    /// - Parameter message: The message to record.
    public func notice(_ message: QGLogMessage) { emit("NOTICE", message) }

    /// Logs at warning severity — 227 of this ecosystem's 287 call sites.
    /// - Parameter message: The message to record.
    public func warning(_ message: QGLogMessage) { emit("WARNING", message) }

    /// Logs at error severity.
    /// - Parameter message: The message to record.
    public func error(_ message: QGLogMessage) { emit("ERROR", message) }

    /// Logs at critical severity.
    /// - Parameter message: The message to record.
    public func critical(_ message: QGLogMessage) { emit("CRITICAL", message) }

    /// Logs at fault severity.
    /// - Parameter message: The message to record.
    public func fault(_ message: QGLogMessage) { emit("FAULT", message) }

    /// The text `emit` would write, or `nil` when logging is off.
    ///
    /// Exposed so the rendering is testable without capturing a file descriptor — the
    /// decision to write and the text written are separable, and only one of them needs a
    /// process to observe.
    public func renderedLine(_ level: String, _ message: QGLogMessage) -> String? {
        guard let enabled = environment()["QG_LOG"], !enabled.isEmpty else {
            return nil
        }
        let tag = subsystem.isEmpty && category.isEmpty ? "" : "[\(subsystem):\(category)] "
        return "\(level) \(tag)\(message.rendered)\n"
    }

    private func emit(_ level: String, _ message: QGLogMessage) {
        guard let line = renderedLine(level, message), let data = line.data(using: .utf8) else { return }
        FileHandle.standardError.write(data)
    }
}

#if !canImport(os)
// Only where Apple's spellings are absent. On Apple these names are Apple's own.
/// `os.OSLogPrivacy` under its Apple spelling, where Apple's does not exist.
public typealias OSLogPrivacy = QGLogPrivacy

/// `os.Logger` under its Apple spelling, where Apple's does not exist.
///
/// This alias is what lets 121 call sites across four packages compile unchanged: they
/// name `Logger`, and on Apple that is Apple's own type re-exported above.
public typealias Logger = QGLogger
#endif
