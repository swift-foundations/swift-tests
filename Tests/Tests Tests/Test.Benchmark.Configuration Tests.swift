import Testing
import Tests_Test_Support

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
    func `Hashable equal configs hash equally`() {
        let a = Test_Primitives.Test.Benchmark.Configuration(
            iterations: 10, warmup: 0, metric: .median
        )
        let b = Test_Primitives.Test.Benchmark.Configuration(
            iterations: 10, warmup: 0, metric: .median
        )
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `Equatable configs`() {
        let a = Test_Primitives.Test.Benchmark.Configuration(
            iterations: 25, warmup: 2, printResults: false,
            threshold: .milliseconds(500), metric: .mean
        )
        let b = Test_Primitives.Test.Benchmark.Configuration(
            iterations: 25, warmup: 2, printResults: false,
            threshold: .milliseconds(500), metric: .mean
        )
        #expect(a == b)
    }
}

// MARK: - EdgeCase

extension BenchmarkConfigurationTests.EdgeCase {
    @Test
    func `different configs are not equal`() {
        let a = Test_Primitives.Test.Benchmark.Configuration(iterations: 10)
        let b = Test_Primitives.Test.Benchmark.Configuration(iterations: 20)
        #expect(a != b)
    }

    @Test
    func `config without threshold`() {
        let config = Test_Primitives.Test.Benchmark.Configuration(threshold: nil)
        #expect(config.threshold == nil)
    }
}
