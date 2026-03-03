//
//  Test.Environment+JSON.swift
//  swift-tests
//
//  JSON.Serializable conformance for Test.Environment.
//

public import JSON
import Time_Primitives

extension Test.Environment: JSON.Serializable {
    /// Serializes the environment as a JSON object.
    ///
    /// Used to write an `environment.json` alongside baselines
    /// for human inspection and debugging.
    public static func serialize(_ value: Self) -> JSON {
        let features: JSON = .object([
            ("NonisolatedNonsendingByDefault", JSON.bool(value.features.nonisolatedNonsendingByDefault)),
            ("StrictMemorySafety", JSON.bool(value.features.strictMemorySafety)),
        ])

        return .object([
            ("architecture", JSON.string(value.architecture)),
            ("physical_cores", JSON.number(value.physicalCPUCount)),
            ("logical_cores", JSON.number(value.logicalCPUCount)),
            ("memory_bytes", JSON.number(Int(value.memoryBytes))),
            ("os", JSON.string(value.osVersion)),
            ("swift_version", JSON.string(value.swiftVersion)),
            ("optimization", JSON.string(value.optimization.rawValue)),
            ("features", features),
            ("fingerprint", JSON.string(value.fingerprint)),
        ])
    }

    /// Deserializes an environment from JSON.
    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
        guard let architecture = try? Swift.String(json: json.architecture) else {
            throw .missingKey("architecture")
        }
        guard let physicalCores = try? Int(json: json.physical_cores) else {
            throw .missingKey("physical_cores")
        }
        guard let logicalCores = try? Int(json: json.logical_cores) else {
            throw .missingKey("logical_cores")
        }
        guard let memoryBytes = try? Int(json: json.memory_bytes) else {
            throw .missingKey("memory_bytes")
        }
        guard let os = try? Swift.String(json: json.os) else {
            throw .missingKey("os")
        }
        guard let swiftVersion = try? Swift.String(json: json.swift_version) else {
            throw .missingKey("swift_version")
        }
        guard let optimization = try? Swift.String(json: json.optimization) else {
            throw .missingKey("optimization")
        }

        let nnbd = (try? Bool(json: json.features.NonisolatedNonsendingByDefault)) ?? false
        let sms = (try? Bool(json: json.features.StrictMemorySafety)) ?? false

        return Self(
            architecture: architecture,
            physicalCPUCount: physicalCores,
            logicalCPUCount: logicalCores,
            memoryBytes: UInt64(memoryBytes),
            osVersion: os,
            swiftVersion: swiftVersion,
            optimization: .init(rawValue: optimization),
            features: .init(
                nonisolatedNonsendingByDefault: nnbd,
                strictMemorySafety: sms
            )
        )
    }
}
