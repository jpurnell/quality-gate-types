import Foundation

/// The Tier-2 plugin contract (quality-gate Phase 4b), version 1.
///
/// A plugin is any executable speaking JSON over stdio:
/// - `<plugin> contract` → prints a ``PluginDescriptor``.
/// - `<plugin> check` with a ``PluginCheckRequest`` on stdin → prints a
///   `CheckResult`.
///
/// The host skips plugins declaring an unknown/newer contract version (with
/// a note — the same tolerance policy as corpus schema versioning), and
/// treats timeouts, non-zero exits, and malformed output as a
/// `plugin-error` diagnostic, never a crash.
public enum PluginContract {
    /// The contract version this vocabulary describes.
    public static let currentVersion = 1
}

/// A plugin's self-description, printed by its `contract` verb.
public struct PluginDescriptor: Sendable, Codable, Equatable {
    /// The contract version the plugin speaks.
    public let contractVersion: Int
    /// Checker identifier used in reports and telemetry origin tags.
    public let checkerId: String
    /// Human-readable plugin name.
    public let name: String
    /// Whether the host may run this plugin concurrently with other checkers.
    public let parallelSafe: Bool

    /// Creates a descriptor.
    /// - Parameters:
    ///   - contractVersion: The contract version the plugin speaks.
    ///   - checkerId: Checker identifier for reports and origin tags.
    ///   - name: Human-readable plugin name.
    ///   - parallelSafe: Whether concurrent execution is safe.
    public init(contractVersion: Int, checkerId: String, name: String, parallelSafe: Bool) {
        self.contractVersion = contractVersion
        self.checkerId = checkerId
        self.name = name
        self.parallelSafe = parallelSafe
    }
}

/// The host's `check` request, delivered to the plugin on stdin.
public struct PluginCheckRequest: Sendable, Codable, Equatable {
    /// The contract version the host speaks.
    public let contractVersion: Int
    /// Root of the project under analysis.
    public let projectRoot: String
    /// Changed-file hints (paths relative to `projectRoot`); empty means the
    /// plugin should scan its full territory.
    public let changedFiles: [String]
    /// The plugin's `config:` block from the host's configuration, passed
    /// through verbatim.
    public let config: JSONValue?
    /// Directory the plugin may write artifacts into. Resolved by the host's
    /// run environment, so foreign-mode write discipline binds plugins too —
    /// a plugin never writes into a repo the run couldn't. Nil means the
    /// plugin must not write artifacts.
    public let artifactsDirectory: String?

    /// Creates a check request.
    /// - Parameters:
    ///   - contractVersion: The contract version the host speaks.
    ///   - projectRoot: Root of the project under analysis.
    ///   - changedFiles: Changed-file hints; empty for a full scan.
    ///   - config: The plugin's configuration block, verbatim.
    ///   - artifactsDirectory: Host-resolved artifact destination, or nil.
    public init(
        contractVersion: Int = PluginContract.currentVersion,
        projectRoot: String,
        changedFiles: [String] = [],
        config: JSONValue? = nil,
        artifactsDirectory: String? = nil
    ) {
        self.contractVersion = contractVersion
        self.projectRoot = projectRoot
        self.changedFiles = changedFiles
        self.config = config
        self.artifactsDirectory = artifactsDirectory
    }
}

/// Arbitrary JSON, preserved verbatim — the shape of a plugin's `config:`
/// block, which the host never interprets.
public indirect enum JSONValue: Sendable, Codable, Equatable {
    /// A JSON string.
    case string(String)
    /// A JSON number (represented as Double, like JSON itself).
    case number(Double)
    /// A JSON boolean.
    case bool(Bool)
    /// JSON null.
    case null
    /// A JSON array.
    case array([JSONValue])
    /// A JSON object.
    case object([String: JSONValue])

    /// Decodes whichever JSON shape is present.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Not a JSON value")
        }
    }

    /// Encodes the underlying JSON shape.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}
