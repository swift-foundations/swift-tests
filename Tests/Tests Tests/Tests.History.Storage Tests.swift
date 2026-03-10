import Testing
import Tests_Test_Support

extension Tests.History.Storage {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit

extension Tests.History.Storage.Test.Unit {
    @Test
    func `path includes module and name with jsonl extension`() {
        let root = File.Path(stringLiteral: "/history")
        let id = Tests_Core.Test.ID.stub("myTest", module: "MyModule")

        let path = Tests.History.Storage.path(
            root: root, testID: id, fingerprint: "arm64-10c-debug"
        )
        let str = Swift.String(path)

        #expect(str.contains("MyModule"))
        #expect(str.contains("myTest"))
        #expect(str.hasSuffix("arm64-10c-debug.jsonl"))
    }

    @Test
    func `path includes suite when present`() {
        let root = File.Path(stringLiteral: "/history")
        let id = Tests_Core.Test.ID.stub("myTest", module: "Mod", suite: "MySuite")

        let path = Tests.History.Storage.path(root: root, testID: id, fingerprint: "fp")

        #expect(Swift.String(path).contains("MySuite"))
    }

    @Test
    func `path splits nested suite into components`() {
        let root = File.Path(stringLiteral: "/history")
        let id = Tests_Core.Test.ID.stub("myTest", module: "M", suite: "Outer.Inner")

        let path = Tests.History.Storage.path(root: root, testID: id, fingerprint: "fp")
        let str = Swift.String(path)

        #expect(str.contains("Outer"))
        #expect(str.contains("Inner"))
    }

    @Test
    func `append and load roundtrip preserves records`() throws {
        let id = Tests_Core.Test.ID.stub("benchTest", module: "Mod")
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [
            .milliseconds(10), .milliseconds(12), .milliseconds(11),
        ])
        let environment = Test_Primitives.Test.Environment.capture()

        let record = Tests.History.Record(
            timestamp: 1710100000.0,
            testID: id,
            metric: .median,
            metricValue: .milliseconds(11),
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: 3.2,
            outlierCount: 0
        )

        try File.Directory.temporary { dir in
            let root = dir.path / "benchmarks"

            try Tests.History.Storage.append(record, root: root)

            let records = Tests.History.Storage.load(
                root: root,
                testID: id,
                fingerprint: environment.fingerprint
            )

            #expect(records.count == 1)
            #expect(records.first?.testID.name == "benchTest")
            #expect(records.first?.timestamp == 1710100000.0)
        }
    }

    @Test
    func `append accumulates multiple records`() throws {
        let id = Tests_Core.Test.ID.stub("t", module: "M")
        let environment = Test_Primitives.Test.Environment.capture()

        try File.Directory.temporary { dir in
            let root = dir.path / "benchmarks"

            for i in 0..<5 {
                let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [
                    .milliseconds(10 + i),
                ])
                let record = Tests.History.Record(
                    timestamp: Double(1710100000 + i),
                    testID: id,
                    metric: .median,
                    metricValue: .milliseconds(10 + i),
                    measurement: measurement,
                    environment: environment,
                    coefficientOfVariation: nil,
                    outlierCount: nil
                )
                try Tests.History.Storage.append(record, root: root)
            }

            let records = Tests.History.Storage.load(
                root: root,
                testID: id,
                fingerprint: environment.fingerprint
            )

            #expect(records.count == 5)
        }
    }

    @Test
    func `append creates parent directories`() throws {
        let id = Tests_Core.Test.ID.stub("t", module: "Deep")
        let environment = Test_Primitives.Test.Environment.capture()
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [.seconds(1)])

        let record = Tests.History.Record(
            timestamp: 1.0,
            testID: id,
            metric: .median,
            metricValue: .seconds(1),
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: nil,
            outlierCount: nil
        )

        try File.Directory.temporary { dir in
            let root = dir.path / "deep" / "nested" / "benchmarks"
            try Tests.History.Storage.append(record, root: root)

            let records = Tests.History.Storage.load(
                root: root,
                testID: id,
                fingerprint: environment.fingerprint
            )
            #expect(records.count == 1)
        }
    }
}

// MARK: - EdgeCase

extension Tests.History.Storage.Test.EdgeCase {
    @Test
    func `load returns empty for nonexistent path`() {
        let path = File.Path(stringLiteral: "/tmp/swift-tests-nonexistent-history-e7f2c4a1.jsonl")
        #expect(Tests.History.Storage.load(at: path).isEmpty)
    }

    @Test
    func `path omits suite directory when nil`() {
        let root = File.Path(stringLiteral: "/history")
        let noSuite = Tests_Core.Test.ID.stub("test", module: "Mod")
        let withSuite = Tests_Core.Test.ID.stub("test", module: "Mod", suite: "S")

        let path1 = Tests.History.Storage.path(root: root, testID: noSuite, fingerprint: "fp")
        let path2 = Tests.History.Storage.path(root: root, testID: withSuite, fingerprint: "fp")

        #expect(Swift.String(path1).count < Swift.String(path2).count)
    }

    @Test
    func `path sanitizes special characters`() {
        let root = File.Path(stringLiteral: "/history")
        let id = Tests_Core.Test.ID.stub("my test()", module: "My Module!")

        let path = Tests.History.Storage.path(root: root, testID: id, fingerprint: "fp")
        let str = Swift.String(path)

        #expect(!str.contains(" "))
        #expect(!str.contains("!"))
        #expect(!str.contains("("))
        #expect(!str.contains(")"))
    }
}
