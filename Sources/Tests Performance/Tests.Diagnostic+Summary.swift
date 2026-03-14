//
//  Tests.Diagnostic+Summary.swift
//  swift-tests
//
//  Summary table formatter for collected performance diagnostics.
//

import Formatting_Primitives
import Time_Primitives
import Console

extension Tests.Diagnostic {
    /// Prints a summary comparison table from an array of diagnostics.
    ///
    /// The table is sorted by qualified name and shows median and min
    /// for each test. When called after all `.timed()` tests complete,
    /// this provides a single view of all performance results.
    public static func summary(_ diagnostics: [Tests.Diagnostic]) {
        guard !diagnostics.isEmpty else { return }

        let sorted = diagnostics.sorted { $0.qualifiedName < $1.qualifiedName }
        let cap = Tests.consoleCapability

        // Column widths
        let nameWidth = max(
            sorted.map(\.qualifiedName.count).max() ?? 0,
            4 // "Test"
        )
        let medianWidth = 12
        let minWidth = 12

        // Header
        let header = Console.Style.bold.apply(to: "PERFORMANCE SUMMARY", capability: cap)
        print("\n\(header)")
        print("")

        let nameHeader = _pad("Test", to: nameWidth)
        print("| \(nameHeader) |     Median |        Min |")
        print("|\(_line(nameWidth))|------------|------------|")

        // Rows
        for diagnostic in sorted {
            let m = diagnostic.measurement
            let name = _pad(diagnostic.qualifiedName, to: nameWidth)
            let median = _right(m.median.formatted(), width: medianWidth - 2)
            let min = _right(m.min.formatted(), width: minWidth - 2)
            print("| \(name) | \(median) | \(min) |")
        }

        print("")
    }

    private static func _pad(_ s: Swift.String, to width: Int) -> Swift.String {
        if s.count >= width { return s }
        return s + Swift.String(repeating: " ", count: width - s.count)
    }

    private static func _right(_ s: Swift.String, width: Int) -> Swift.String {
        if s.count >= width { return s }
        return Swift.String(repeating: " ", count: width - s.count) + s
    }

    private static func _line(_ width: Int) -> Swift.String {
        Swift.String(repeating: "-", count: width + 2)
    }
}
