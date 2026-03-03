//
//  Tests.Measurement+JSON.swift
//  swift-tests
//
//  JSON.Serializable conformance for Tests.Measurement.
//

public import JSON
import Time_Primitives

extension Tests.Measurement: JSON.Serializable {
    /// Serializes a measurement as a JSON object with a durations array.
    ///
    /// Format:
    /// ```json
    /// { "durations_seconds": [0.001234, 0.001189, ...] }
    /// ```
    public static func serialize(_ value: Self) -> JSON {
        let durations: [JSON] = value.durations.map { JSON.number($0.inSeconds) }
        return .object([
            ("durations_seconds", .array(durations))
        ])
    }

    /// Deserializes a measurement from JSON.
    ///
    /// Parses the `durations_seconds` array and reconstructs the measurement,
    /// recomputing batch statistics from the restored durations.
    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
        guard let array = json.durations_seconds.array else {
            throw .missingKey("durations_seconds")
        }

        var durations: [Duration] = []
        durations.reserveCapacity(array.count)

        for element in array {
            guard let seconds = try? Double(json: element) else {
                throw .typeMismatch(expected: "number", got: "\(element)")
            }
            durations.append(.seconds(seconds))
        }

        return Self(durations: durations)
    }
}
