import Testing
import Tests
import Test_Primitives

@Suite("Test.Benchmark.Configuration")
struct BenchmarkConfigurationTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit

extension BenchmarkConfigurationTests.Unit {
    @Test
    func `default values match specification`() {
        let config = Test_Primitives.Test.Benchmark.Configuration()
        #expect(config.iterations == 10)
        #expect(config.warmup == 0)
        #expect(config.printResults == true)
        #expect(config.threshold == nil)
        #expect(config.metric == .median)
    }

    @Test
    func `custom init stores all values`() {
        let config = Test_Primitives.Test.Benchmark.Configuration(
            iterations: 50,
            warmup: 5,
            printResults: false,
            threshold: .milliseconds(100),
            metric: .p95
        )
        #expect(config.iterations == 50)
        #expect(config.warmup == 5)
        #expect(config.printResults == false)
        #expect(config.threshold == .milliseconds(100))
        #expect(config.metric == .p95)
    }

    @Test
    func `encode produces semicolon-delimited string`() {
        let config = Test_Primitives.Test.Benchmark.Configuration(
            iterations: 20, warmup: 3, printResults: true, metric: .p99
        )
        let encoded = config.encode()
        #expect(encoded.contains("i=20"))
        #expect(encoded.contains("w=3"))
        #expect(encoded.contains("p=true"))
        #expect(encoded.contains("m=p99"))
    }

    @Test
    func `decode round trips from encode`() {
        let original = Test_Primitives.Test.Benchmark.Configuration(
            iterations: 25, warmup: 2, printResults: false, metric: .mean
        )
        let encoded = original.encode()
        let decoded = Test_Primitives.Test.Benchmark.Configuration.decode(from: encoded)
        #expect(decoded != nil)
        #expect(decoded?.iterations == 25)
        #expect(decoded?.warmup == 2)
        #expect(decoded?.printResults == false)
        #expect(decoded?.metric == .mean)
    }

    @Test
    func `decode with threshold preserves duration`() {
        let original = Test_Primitives.Test.Benchmark.Configuration(
            threshold: .milliseconds(500), metric: .p95
        )
        let encoded = original.encode()
        let decoded = Test_Primitives.Test.Benchmark.Configuration.decode(from: encoded)
        #expect(decoded?.threshold == .milliseconds(500))
    }

    @Test
    func `Hashable equal configs hash equally`() {
        let a = Test_Primitives.Test.Benchmark.Configuration(
            iterations: 10, warmup: 0, metric: .median
        )
        let b = Test_Primitives.Test.Benchmark.Configuration(
            iterations: 10, warmup: 0, metric: .median
        )
        #expect(a.hashValue == b.hashValue)
    }
}

// MARK: - EdgeCase

extension BenchmarkConfigurationTests.EdgeCase {
    @Test
    func `decode returns defaults for malformed values`() {
        let decoded = Test_Primitives.Test.Benchmark.Configuration.decode(from: "i=abc;w=xyz")
        #expect(decoded?.iterations == 10)
        #expect(decoded?.warmup == 0)
    }

    @Test
    func `decode ignores unknown keys`() {
        let decoded = Test_Primitives.Test.Benchmark.Configuration.decode(
            from: "x=foo;i=5;z=bar"
        )
        #expect(decoded?.iterations == 5)
    }

    @Test
    func `encode without threshold omits t key`() {
        let config = Test_Primitives.Test.Benchmark.Configuration(threshold: nil)
        let encoded = config.encode()
        #expect(!encoded.contains("t="))
    }
}
