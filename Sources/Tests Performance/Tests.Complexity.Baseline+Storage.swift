//
//  Tests.Complexity.Baseline+Storage.swift
//  swift-tests
//
//  File-backed storage for complexity baselines using the existing
//  Tests.Baseline.Storage directory convention.
//

public import File_System
public import JSON

// MARK: - JSON Serializable

extension Tests.Complexity.Baseline: JSON.Serializable {
    public static func serialize(_ value: Self) -> JSON {
        var pairs: [(Swift.String, JSON)] = []

        if let cls = value.bestClass {
            pairs.append(("bestClass", .string(cls.rawValue)))
        } else {
            pairs.append(("bestClass", .null))
        }

        pairs.append(("exponent", .number(value.exponent)))
        pairs.append(("confidence", .string(value.confidence.rawValue)))

        if let r2 = value.bestRSquared {
            pairs.append(("bestRSquared", .number(r2)))
        } else {
            pairs.append(("bestRSquared", .null))
        }

        return .object(pairs)
    }

    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
        // bestClass: optional string
        let bestClass: Test.Benchmark.Complexity.Class?
        if json.bestClass.isNull || !json.bestClass.isString {
            bestClass = nil
        } else {
            bestClass = Test.Benchmark.Complexity.Class(
                rawValue: try Swift.String.deserialize(json.bestClass)
            )
        }

        // exponent: required number
        guard let exponent = Double(json.exponent) else {
            throw .missingKey("exponent")
        }

        // confidence: required string
        let confidence: Tests.Complexity.Confidence
        if json.confidence.isString {
            let str = try Swift.String.deserialize(json.confidence)
            confidence = Tests.Complexity.Confidence(rawValue: str) ?? .inconclusive
        } else {
            confidence = .inconclusive
        }

        // bestRSquared: optional number
        let bestRSquared: Double?
        if json.bestRSquared.isNull || !json.bestRSquared.isNumber {
            bestRSquared = nil
        } else {
            bestRSquared = Double(json.bestRSquared)
        }

        return Self(
            bestClass: bestClass,
            exponent: exponent,
            confidence: confidence,
            bestRSquared: bestRSquared
        )
    }
}

// MARK: - File I/O

extension Tests.Complexity.Baseline {

    /// Resolves the complexity baseline file path.
    ///
    /// Uses the same `.benchmarks/` root as performance baselines but
    /// nests under a `complexity/` subdirectory to avoid collision.
    ///
    /// ```
    /// .benchmarks/complexity/{key}.json
    /// ```
    public static func path(
        root: File.Path? = nil,
        key: Swift.String
    ) -> File.Path {
        let baseRoot = root ?? Tests.Baseline.Storage.root()
        return baseRoot / "complexity" / "\(key).json"
    }

    /// Loads a stored complexity baseline, or `nil` if none exists.
    public static func load(at path: File.Path) -> Tests.Complexity.Baseline? {
        let file = File(path)
        guard file.stat.exists else { return nil }

        do {
            return try file.read.full { span in
                let bytes: [UInt8] = span.withUnsafeBufferPointer { .init($0) }
                return try Tests.Complexity.Baseline(jsonBytes: bytes)
            }
        } catch {
            return nil
        }
    }

    /// Saves this baseline to disk. Creates parent directories as needed.
    public func save(
        to path: File.Path
    ) throws(Tests.Baseline.Storage.Error) {
        if let parent = path.parent {
            let dir = File.Directory(parent)
            if !dir.stat.exists {
                do {
                    try dir.create.recursive()
                } catch {
                    throw Tests.Baseline.Storage.Error.directoryCreationFailed(
                        path: Swift.String(describing: parent),
                        underlying: Swift.String(describing: error)
                    )
                }
            }
        }

        let bytes = jsonBytes(pretty: true)
        do {
            try File(path).write.atomic(contentsOf: bytes)
        } catch {
            throw Tests.Baseline.Storage.Error.writeFailed(
                path: Swift.String(describing: path),
                underlying: Swift.String(describing: error)
            )
        }
    }

}
