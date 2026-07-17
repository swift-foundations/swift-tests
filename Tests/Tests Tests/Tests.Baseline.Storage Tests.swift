import Testing
import Tests_Test_Support

extension Tests.Baseline.Storage {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

// MARK: - Unit

extension Tests.Baseline.Storage.Test.Unit {
    @Test
    func `path includes module and name`() {
        let root = File.Path(stringLiteral: "/baselines")
        let id = Tests_Core.Test.ID.stub("myTest", module: "MyModule")

        let path = Tests.Baseline.Storage.path(
            root: root,
            testID: id,
            fingerprint: "arm64-10c-debug"
        )
        let str = Swift.String(path)

        #expect(str.contains("MyModule"))
        #expect(str.contains("myTest"))
        #expect(str.hasSuffix("arm64-10c-debug.json"))
    }

    @Test
    func `path includes suite when present`() {
        let root = File.Path(stringLiteral: "/baselines")
        let id = Tests_Core.Test.ID.stub("myTest", module: "Mod", suite: "MySuite")

        let path = Tests.Baseline.Storage.path(root: root, testID: id, fingerprint: "fp")

        #expect(Swift.String(path).contains("MySuite"))
    }

    @Test
    func `path splits nested suite into components`() {
        let root = File.Path(stringLiteral: "/baselines")
        let id = Tests_Core.Test.ID.stub("myTest", module: "M", suite: "Outer.Inner")

        let path = Tests.Baseline.Storage.path(root: root, testID: id, fingerprint: "fp")
        let str = Swift.String(path)

        #expect(str.contains("Outer"))
        #expect(str.contains("Inner"))
    }

    @Test
    func `path uses fingerprint as json filename`() {
        let root = File.Path(stringLiteral: "/base")
        let id = Tests_Core.Test.ID.stub("t", module: "M")

        let path = Tests.Baseline.Storage.path(
            root: root,
            testID: id,
            fingerprint: "arm64-10c-debug-nnbd-sms"
        )

        #expect(Swift.String(path).hasSuffix("arm64-10c-debug-nnbd-sms.json"))
    }

    @Test
    func `save and load roundtrip preserves durations`() throws {
        let measurement = Test.Benchmark.Measurement(durations: [
            .seconds(1), .seconds(2), .seconds(3),
        ])

        try File.Directory.temporary { dir in
            let path = dir.path / "module" / "test" / "fp.json"
            try Tests.Baseline.Storage.save(measurement, to: path)

            let loaded = Tests.Baseline.Storage.load(at: path)
            #expect(loaded != nil)

            if let loaded {
                #expect(loaded.durations.count == 3)
                for (original, roundtripped) in zip(measurement.durations, loaded.durations) {
                    let diff = abs(original.inSeconds - roundtripped.inSeconds)
                    #expect(diff < 0.000001)
                }
            }
        }
    }

    @Test
    func `save creates parent directories`() throws {
        let measurement = Test.Benchmark.Measurement(durations: [.seconds(1)])

        try File.Directory.temporary { dir in
            let path = dir.path / "deep" / "nested" / "dir" / "fp.json"
            try Tests.Baseline.Storage.save(measurement, to: path)
            #expect(Tests.Baseline.Storage.load(at: path) != nil)
        }
    }
}

// MARK: - EdgeCase

extension Tests.Baseline.Storage.Test.EdgeCase {
    @Test
    func `path omits suite directory when nil`() {
        let root = File.Path(stringLiteral: "/baselines")
        let noSuite = Tests_Core.Test.ID.stub("test", module: "Mod")
        let withSuite = Tests_Core.Test.ID.stub("test", module: "Mod", suite: "S")

        let path1 = Tests.Baseline.Storage.path(root: root, testID: noSuite, fingerprint: "fp")
        let path2 = Tests.Baseline.Storage.path(root: root, testID: withSuite, fingerprint: "fp")

        #expect(Swift.String(path1).count < Swift.String(path2).count)
    }

    @Test
    func `path uses test ID components directly`() {
        let root = File.Path(stringLiteral: "/baselines")
        let id = Tests_Core.Test.ID.stub("testLogin", module: "AuthModule", suite: "AuthSuite")

        let path = Tests.Baseline.Storage.path(root: root, testID: id, fingerprint: "fp")
        let str = Swift.String(path)

        #expect(str.contains("AuthModule"))
        #expect(str.contains("AuthSuite"))
        #expect(str.contains("testLogin"))
        #expect(str.hasSuffix("fp.json"))
    }

    @Test
    func `load returns nil for nonexistent path`() {
        let path = File.Path(stringLiteral: "/tmp/swift-tests-nonexistent-e7f2c4a1.json")
        #expect(Tests.Baseline.Storage.load(at: path) == nil)
    }
}
