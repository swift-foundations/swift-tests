import JSON
import Testing
import Tests_Test_Support

extension Test_Primitives.Test.Benchmark.Measurement.Test {
    @Suite struct JSON {}
}

// MARK: - JSON

extension Test_Primitives.Test.Benchmark.Measurement.Test.JSON {
    @Test
    func `serialize and deserialize preserves durations`() throws {
        let original = Test.Benchmark.Measurement(durations: [
            .seconds(1), .seconds(2), .seconds(3),
        ])

        let json = Test.Benchmark.Measurement.serialize(original)
        let roundtripped = try Test.Benchmark.Measurement.deserialize(json)

        #expect(roundtripped.durations.count == original.durations.count)
        for (a, b) in zip(original.durations, roundtripped.durations) {
            #expect(abs(a.inSeconds - b.inSeconds) < 0.000001)
        }
    }

    @Test
    func `roundtrip with millisecond values`() throws {
        let original = Test.Benchmark.Measurement.with([10, 50, 100, 200, 500])

        let json = Test.Benchmark.Measurement.serialize(original)
        let roundtripped = try Test.Benchmark.Measurement.deserialize(json)

        #expect(roundtripped.durations.count == 5)
        for (a, b) in zip(original.durations, roundtripped.durations) {
            #expect(abs(a.inSeconds - b.inSeconds) < 0.000001)
        }
    }

    @Test
    func `empty durations roundtrip`() throws {
        let original = Test.Benchmark.Measurement(durations: [])

        let json = Test.Benchmark.Measurement.serialize(original)
        let roundtripped = try Test.Benchmark.Measurement.deserialize(json)

        #expect(roundtripped.durations.isEmpty)
    }

    @Test
    func `single duration roundtrip`() throws {
        let original = Test.Benchmark.Measurement(durations: [.seconds(42)])

        let json = Test.Benchmark.Measurement.serialize(original)
        let roundtripped = try Test.Benchmark.Measurement.deserialize(json)

        #expect(roundtripped.durations.count == 1)
        #expect(abs(roundtripped.durations[0].inSeconds - 42.0) < 0.000001)
    }

    @Test
    func `missing key throws error`() {
        let empty: JSON = .object([])
        #expect(throws: JSON.Error.self) {
            _ = try Test.Benchmark.Measurement.deserialize(empty)
        }
    }
}
