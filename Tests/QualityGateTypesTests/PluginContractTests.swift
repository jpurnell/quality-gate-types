import Testing
import Foundation
@testable import QualityGateTypes

@Suite("PluginContract")
struct PluginContractTests {

    @Test("descriptor round-trips with stable keys")
    func descriptorRoundTrip() throws {
        let descriptor = PluginDescriptor(
            contractVersion: 1, checkerId: "vigil", name: "swift-vigil", parallelSafe: true)
        let data = try JSONEncoder().encode(descriptor)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"contractVersion\""))
        #expect(json.contains("\"checkerId\""))
        let decoded = try JSONDecoder().decode(PluginDescriptor.self, from: data)
        #expect(decoded == descriptor)
    }

    @Test("check request round-trips with a verbatim config block")
    func requestRoundTrip() throws {
        let request = PluginCheckRequest(
            projectRoot: "/work/project",
            changedFiles: ["Sources/A.swift"],
            config: .object([
                "runs": .number(5),
                "strict": .bool(true),
                "markers": .array([.string("// TIMING:")]),
            ]),
            artifactsDirectory: "/artifacts")
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(PluginCheckRequest.self, from: data)
        #expect(decoded == request)
        #expect(decoded.contractVersion == PluginContract.currentVersion)
    }

    @Test("request defaults: current version, full scan, no config, no artifacts")
    func requestDefaults() {
        let request = PluginCheckRequest(projectRoot: "/p")
        #expect(request.contractVersion == 1)
        #expect(request.changedFiles.isEmpty)
        #expect(request.config == nil)
        #expect(request.artifactsDirectory == nil)
    }

    @Test("JSONValue decodes every shape from raw JSON")
    func jsonValueShapes() throws {
        let raw = #"{"s":"x","n":2.5,"b":false,"z":null,"a":[1],"o":{"k":"v"}}"#
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(raw.utf8))
        guard case .object(let object) = value else {
            Issue.record("expected object, got \(value)")
            return
        }
        #expect(object["s"] == .string("x"))
        #expect(object["n"] == .number(2.5))
        #expect(object["b"] == .bool(false))
        #expect(object["z"] == JSONValue.null)
        #expect(object["a"] == .array([.number(1)]))
        #expect(object["o"] == .object(["k": .string("v")]))
    }

    @Test("a plugin response is a plain CheckResult — the shared vocabulary")
    func responseIsCheckResult() throws {
        let response = CheckResult(
            checkerId: "vigil",
            status: .warning,
            diagnostics: [Diagnostic(
                severity: .warning,
                message: "definitive race",
                ruleId: "test.stress-flip")],
            duration: .milliseconds(12))
        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(CheckResult.self, from: data)
        #expect(decoded.checkerId == "vigil")
        #expect(decoded.diagnostics.first?.ruleId == "test.stress-flip")
    }
}
