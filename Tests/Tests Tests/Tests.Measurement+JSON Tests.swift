import Testing
import Tests_Test_Support
import JSON

extension Tests.Measurement.Test {
    @Suite struct JSON {}
}

// MARK: - JSON

extension Tests.Measurement.Test.JSON {
    @Test
    func `serialize and deserialize preserves durations`() throws {
        let original = Tests.Measurement(durations: [
            .seconds(1), .seconds(2), .seconds(3),
        ])

        let json = Tests.Measurement.serialize(original)
        let roundtripped = try Tests.Measurement.deserialize(json)

        #expect(roundtripped.durations.count == original.durations.count)
        for (a, b) in zip(original.durations, roundtripped.durations) {
            #expect(abs(a.inSeconds - b.inSeconds) < 0.000001)
        }
    }

    @Test
    func `roundtrip with millisecond values`() throws {
        let original = Tests.Measurement.with([10, 50, 100, 200, 500])

        let json = Tests.Measurement.serialize(original)
        let roundtripped = try Tests.Measurement.deserialize(json)

        #expect(roundtripped.durations.count == 5)
        for (a, b) in zip(original.durations, roundtripped.durations) {
            #expect(abs(a.inSeconds - b.inSeconds) < 0.000001)
        }
    }

    @Test
    func `empty durations roundtrip`() throws {
        let original = Tests.Measurement(durations: [])

        let json = Tests.Measurement.serialize(original)
        let roundtripped = try Tests.Measurement.deserialize(json)

        #expect(roundtripped.durations.isEmpty)
    }

    @Test
    func `single duration roundtrip`() throws {
        let original = Tests.Measurement(durations: [.seconds(42)])

        let json = Tests.Measurement.serialize(original)
        let roundtripped = try Tests.Measurement.deserialize(json)

        #expect(roundtripped.durations.count == 1)
        #expect(abs(roundtripped.durations[0].inSeconds - 42.0) < 0.000001)
    }

    @Test
    func `missing key throws error`() {
        let empty: JSON = .object([])
        #expect(throws: JSON.Error.self) {
            _ = try Tests.Measurement.deserialize(empty)
        }
    }
}
