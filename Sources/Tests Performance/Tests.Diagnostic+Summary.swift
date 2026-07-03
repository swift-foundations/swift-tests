//
//  Tests.Diagnostic+Summary.swift
//  swift-tests
//
//  Summary table formatter for collected performance diagnostics.
//

import Console
import Format_Primitives
import Time_Primitives

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
        let format: Time.Format = .duration.precision(3)

        // Strip common module prefix for compact display
        let displayNames = _stripCommonPrefix(sorted.map(\.qualifiedName))

        // Column widths
        let nameWidth = max(
            displayNames.map(\.count).max() ?? 0,
            4  // "Test"
        )

        // Header
        let header = Console.Style.bold.apply(to: "PERFORMANCE SUMMARY", capability: cap)
        print("\n\(header)")
        print("")

        let nameHeader = _pad("Test", to: nameWidth)
        print("| \(nameHeader) |     Median |        Min |")
        print("|\(_line(nameWidth))|------------|------------|")

        // Rows
        for (diagnostic, displayName) in zip(sorted, displayNames) {
            let m = diagnostic.measurement
            let name = _pad(displayName, to: nameWidth)
            let median = _right(m.median.formatted(format), width: 10)
            let min = _right(m.min.formatted(format), width: 10)
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

    /// Strips the longest common dot-separated prefix from all names.
    ///
    /// `["M.A._10", "M.A._20", "M.B._10"]` → `["A._10", "A._20", "B._10"]`
    private static func _stripCommonPrefix(_ names: [Swift.String]) -> [Swift.String] {
        guard let first = names.first else { return names }
        let parts = first.split(separator: ".")
        var shared = 0
        for i in 0..<parts.count {
            let prefix = parts[0...i].joined(separator: ".")
            let dotPrefix = prefix + "."
            if names.allSatisfy({ $0.hasPrefix(dotPrefix) }) {
                shared = i + 1
            } else {
                break
            }
        }
        guard shared > 0 else { return names }
        let dropLength = parts[0..<shared].joined(separator: ".").count + 1  // +1 for trailing dot
        return names.map { Swift.String($0.dropFirst(dropLength)) }
    }
}
