//
//  Test.Environment+JSON.swift
//  swift-tests
//
//  JSON.Serializable conformance for Test.Environment.
//

import Cardinal_Primitives
public import JSON
public import Kernel
import Tagged_Primitives
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
            ("physical_cores", JSON.number(Int(bitPattern: value.physicalCPUCount.underlying.rawValue))),
            ("logical_cores", JSON.number(Int(bitPattern: value.logicalCPUCount.underlying.rawValue))),
            ("memory_bytes", JSON.number(Int(bitPattern: value.memoryBytes.underlying.rawValue))),
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
            physicalCPUCount: System.Processor.Count(_unchecked: Cardinal(UInt(physicalCores))),
            logicalCPUCount: System.Processor.Count(_unchecked: Cardinal(UInt(logicalCores))),
            memoryBytes: System.Memory.Capacity(_unchecked: Cardinal(UInt(memoryBytes))),
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
