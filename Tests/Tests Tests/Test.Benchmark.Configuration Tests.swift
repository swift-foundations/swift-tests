import Testing
import Tests_Test_Support

extension Test_Primitives.Test.Benchmark.Configuration {
    @Suite("Test.Benchmark.Configuration")
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit

extension Test_Primitives.Test.Benchmark.Configuration.Test.Unit {
    @Test
    func `default values match specification`() {
        let config = Test_Primitives.Test.Benchmark.Configuration()
        #expect(config.iteration.count == 10)
        #expect(config.iteration.warmup == 0)
        #expect(config.evaluation.printResults == true)
        #expect(config.evaluation.threshold == nil)
        #expect(config.evaluation.metric == .median)
    }

    @Test
    func `custom init stores all values`() {
        let config = Test_Primitives.Test.Benchmark.Configuration(
            iteration: .init(count: 50, warmup: 5),
            evaluation: .init(
                threshold: .milliseconds(100),
                metric: .p95,
                printResults: false
            )
        )
        #expect(config.iteration.count == 50)
        #expect(config.iteration.warmup == 5)
        #expect(config.evaluation.printResults == false)
        #expect(config.evaluation.threshold == .milliseconds(100))
        #expect(config.evaluation.metric == .p95)
    }

    @Test
    func `Hashable equal configs hash equally`() {
        let a = Test_Primitives.Test.Benchmark.Configuration(
            iteration: .init(count: 10, warmup: 0),
            evaluation: .init(metric: .median)
        )
        let b = Test_Primitives.Test.Benchmark.Configuration(
            iteration: .init(count: 10, warmup: 0),
            evaluation: .init(metric: .median)
        )
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `Equatable configs`() {
        let a = Test_Primitives.Test.Benchmark.Configuration(
            iteration: .init(count: 25, warmup: 2),
            evaluation: .init(
                threshold: .milliseconds(500),
                metric: .mean,
                printResults: false
            )
        )
        let b = Test_Primitives.Test.Benchmark.Configuration(
            iteration: .init(count: 25, warmup: 2),
            evaluation: .init(
                threshold: .milliseconds(500),
                metric: .mean,
                printResults: false
            )
        )
        #expect(a == b)
    }
}

// MARK: - EdgeCase

extension Test_Primitives.Test.Benchmark.Configuration.Test.EdgeCase {
    @Test
    func `different configs are not equal`() {
        let a = Test_Primitives.Test.Benchmark.Configuration(
            iteration: .init(count: 10)
        )
        let b = Test_Primitives.Test.Benchmark.Configuration(
            iteration: .init(count: 20)
        )
        #expect(a != b)
    }

    @Test
    func `config without threshold`() {
        let config = Test_Primitives.Test.Benchmark.Configuration(
            evaluation: .init(threshold: nil)
        )
        #expect(config.evaluation.threshold == nil)
    }
}
