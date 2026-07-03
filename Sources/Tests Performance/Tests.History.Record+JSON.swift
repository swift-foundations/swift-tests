//
//  Tests.History.Record+JSON.swift
//  swift-tests
//
//  JSON serialization for history records.
//

public import JSON
import Source_Primitives
import Time_Primitives

extension Tests.History.Record: JSON.Serializable {
    /// Serializes a record as a compact JSON object for JSONL storage.
    ///
    /// Format:
    /// ```json
    /// {"ts":1710100000.0,"id":{"m":"Mod","s":"Suite","n":"test"},"metric":"median","value_s":0.001,"durations_s":[...],"env":{...},"cv":3.2,"outliers":0}
    /// ```
    public static func serialize(_ value: Self) -> JSON {
        let id: JSON = .object([
            ("m", .string(value.testID.module)),
            ("s", value.testID.suite.map { .string($0) } ?? .null),
            ("n", .string(value.testID.name)),
        ])

        let durations: [JSON] = value.measurement.durations.map {
            .number($0.inSeconds)
        }

        let env = Test.Environment.serialize(value.environment)

        let tsSeconds =
            Double(value.timestamp.secondsSinceUnixEpoch)
            + Double(value.timestamp.nanosecondFraction) / 1_000_000_000
        var fields: [(Swift.String, JSON)] = [
            ("ts", .number(tsSeconds)),
            ("id", id),
            ("metric", .string("\(value.metric)")),
            ("value_s", .number(value.metricValue.inSeconds)),
            ("durations_s", .array(durations)),
            ("env", env),
        ]

        if let cv = value.coefficientOfVariation {
            fields.append(("cv", .number(cv)))
        }
        if let outliers = value.outlierCount {
            fields.append(("outliers", .number(outliers)))
        }

        return .object(fields)
    }

    /// Deserializes a record from JSON.
    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
        guard let tsSeconds = try? Double(json: json.ts) else {
            throw .missingKey("ts")
        }
        let tsWhole = tsSeconds.rounded(.down)
        let ts = Instant(
            _unchecked: (),
            secondsSinceUnixEpoch: Int64(tsWhole),
            nanosecondFraction: Int32((tsSeconds - tsWhole) * 1_000_000_000)
        )

        // Parse test ID
        guard let module = try? Swift.String(json: json.id.m) else {
            throw .missingKey("id.m")
        }
        let suite = try? Swift.String(json: json.id.s)
        guard let name = try? Swift.String(json: json.id.n) else {
            throw .missingKey("id.n")
        }
        let testID = Test.ID(
            module: module,
            suite: suite,
            name: name,
            sourceLocation: Source.Location(
                fileID: "\(module)/history",
                filePath: nil,
                line: 0,
                column: 0
            )
        )

        // Parse metric
        guard let metricStr = try? Swift.String(json: json.metric) else {
            throw .missingKey("metric")
        }
        let metric = _parseMetric(metricStr)

        // Parse metric value
        guard let valueSeconds = try? Double(json: json.value_s) else {
            throw .missingKey("value_s")
        }

        // Parse durations
        guard let durationsArray = json.durations_s.array else {
            throw .missingKey("durations_s")
        }
        var durations: [Duration] = []
        durations.reserveCapacity(durationsArray.count)
        for element in durationsArray {
            guard let seconds = try? Double(json: element) else {
                throw .typeMismatch(expected: "number", got: "\(element)")
            }
            durations.append(.seconds(seconds))
        }

        // Parse environment
        let environment = try Test.Environment.deserialize(json.env)

        // Optional fields
        let cv = try? Double(json: json.cv)
        let outliers = try? Int(json: json.outliers)

        return Self(
            timestamp: ts,
            testID: testID,
            metric: metric,
            metricValue: .seconds(valueSeconds),
            measurement: Test.Benchmark.Measurement(durations: durations),
            environment: environment,
            coefficientOfVariation: cv,
            outlierCount: outliers
        )
    }
}

// MARK: - Metric Parsing

/// Parses a metric string back to its enum case.
private func _parseMetric(_ string: Swift.String) -> Test.Benchmark.Metric {
    switch string {
    case "min": .min
    case "max": .max
    case "median": .median
    case "mean": .mean
    case "p50": .p50
    case "p75": .p75
    case "p90": .p90
    case "p95": .p95
    case "p99": .p99
    case "p999": .p999
    default: .median
    }
}
