import Testing
@testable import Tests_Inline_Snapshot

@Suite("Test.Snapshot.Inline.Rewriter")
struct TestSnapshotInlineRewriterTests {
    @Suite struct HashCount {}
}

// MARK: - Plain text (no hashes needed)

extension TestSnapshotInlineRewriterTests.HashCount {

    @Test
    func plainText() {
        #expect(hashCount(for: "Hello, world!") == 0)
    }

    @Test
    func emptyString() {
        #expect(hashCount(for: "") == 0)
    }

    @Test
    func singleQuote() {
        #expect(hashCount(for: #"She said "hi""#) == 0)
    }

    @Test
    func twoConsecutiveQuotes() {
        #expect(hashCount(for: #"value=""#) == 0)
    }
}

// MARK: - Triple quotes

extension TestSnapshotInlineRewriterTests.HashCount {

    @Test
    func tripleQuotesNeedOneHash() {
        #expect(hashCount(for: #"content with """ in it"#) == 1)
    }

    @Test
    func tripleQuotesFollowedByOneHash() {
        // """# would close a #"""..."""# literal
        #expect(hashCount(for: ##"content with """# in it"##) == 2)
    }

    @Test
    func tripleQuotesFollowedByTwoHashes() {
        #expect(hashCount(for: ###"content with """## in it"###) == 3)
    }
}

// MARK: - Backslash (basic escape prevention)

extension TestSnapshotInlineRewriterTests.HashCount {

    @Test
    func backslashNeedsOneHash() {
        #expect(hashCount(for: #"path\to\file"#) == 1)
    }

    @Test
    func backslashParenNeedsOneHash() {
        // \( is interpolation in a 0-hash literal
        #expect(hashCount(for: #"value is \(x)"#) == 1)
    }
}

// MARK: - Backslash-hash sequences (the bug)

extension TestSnapshotInlineRewriterTests.HashCount {

    @Test
    func backslashHashParenNeedsTwoHashes() {
        // \#( is interpolation in a 1-hash literal → need 2 hashes
        #expect(hashCount(for: ##"value is \#(x)"##) == 2)
    }

    @Test
    func backslashDoubleHashParenNeedsThreeHashes() {
        // \##( is interpolation in a 2-hash literal → need 3 hashes
        #expect(hashCount(for: ###"value is \##(x)"###) == 3)
    }

    @Test
    func backslashHashAloneNeedsTwoHashes() {
        // \# is an escape prefix in a 1-hash literal → need 2 hashes
        #expect(hashCount(for: ##"contains \# sequence"##) == 2)
    }

    @Test
    func backslashHashNNewlineNeedsTwoHashes() {
        // \#n is a newline escape in a 1-hash literal → need 2 hashes
        #expect(hashCount(for: ##"contains \#n newline"##) == 2)
    }

    @Test
    func backslashDoubleHashNNewlineNeedsThreeHashes() {
        // \##n is a newline escape in a 2-hash literal → need 3 hashes
        #expect(hashCount(for: ###"contains \##n newline"###) == 3)
    }
}

// MARK: - Combined

extension TestSnapshotInlineRewriterTests.HashCount {

    @Test
    func tripleQuoteAndBackslashHashTakeMaximum() {
        // """ needs 1, \#( needs 2 → max is 2
        let content = ##"has """ and \#(x)"##
        #expect(hashCount(for: content) == 2)
    }

    @Test
    func tripleQuoteHashAndBackslashTakeMaximum() {
        // """# needs 2, \ needs 1 → max is 2
        let content = ##"has """# and \"##
        #expect(hashCount(for: content) == 2)
    }
}
