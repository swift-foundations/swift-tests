import Testing

@testable import Tests_Inline_Snapshot

extension Test_Primitives.Test.Snapshot.Inline.Rewriter {
    @Suite("Test.Snapshot.Inline.Rewriter")
    struct Test {
        @Suite struct HashCount {}
    }
}

// MARK: - Plain text (no hashes needed)

extension Test_Primitives.Test.Snapshot.Inline.Rewriter.Test.HashCount {

    @Test
    func `plain Text`() {
        #expect(hashCount(for: "Hello, world!") == 0)
    }

    @Test
    func `empty String`() {
        #expect(hashCount(for: "") == 0)
    }

    @Test
    func `single Quote`() {
        #expect(hashCount(for: #"She said "hi""#) == 0)
    }

    @Test
    func `two Consecutive Quotes`() {
        #expect(hashCount(for: #"value=""#) == 0)
    }
}

// MARK: - Triple quotes

extension Test_Primitives.Test.Snapshot.Inline.Rewriter.Test.HashCount {

    @Test
    func `triple Quotes Need One Hash`() {
        #expect(hashCount(for: #"content with """ in it"#) == 1)
    }

    @Test
    func `triple Quotes Followed By One Hash`() {
        // """# would close a #"""..."""# literal
        #expect(hashCount(for: ##"content with """# in it"##) == 2)
    }

    @Test
    func `triple Quotes Followed By Two Hashes`() {
        #expect(hashCount(for: ###"content with """## in it"###) == 3)
    }
}

// MARK: - Backslash (basic escape prevention)

extension Test_Primitives.Test.Snapshot.Inline.Rewriter.Test.HashCount {

    @Test
    func `backslash Needs One Hash`() {
        #expect(hashCount(for: #"path\to\file"#) == 1)
    }

    @Test
    func `backslash Paren Needs One Hash`() {
        // \( is interpolation in a 0-hash literal
        #expect(hashCount(for: #"value is \(x)"#) == 1)
    }
}

// MARK: - Backslash-hash sequences (the bug)

extension Test_Primitives.Test.Snapshot.Inline.Rewriter.Test.HashCount {

    @Test
    func `backslash Hash Paren Needs Two Hashes`() {
        // \#( is interpolation in a 1-hash literal → need 2 hashes
        #expect(hashCount(for: ##"value is \#(x)"##) == 2)
    }

    @Test
    func `backslash Double Hash Paren Needs Three Hashes`() {
        // \##( is interpolation in a 2-hash literal → need 3 hashes
        #expect(hashCount(for: ###"value is \##(x)"###) == 3)
    }

    @Test
    func `backslash Hash Alone Needs Two Hashes`() {
        // \# is an escape prefix in a 1-hash literal → need 2 hashes
        #expect(hashCount(for: ##"contains \# sequence"##) == 2)
    }

    @Test
    func `backslash Hash N Newline Needs Two Hashes`() {
        // \#n is a newline escape in a 1-hash literal → need 2 hashes
        #expect(hashCount(for: ##"contains \#n newline"##) == 2)
    }

    @Test
    func `backslash Double Hash N Newline Needs Three Hashes`() {
        // \##n is a newline escape in a 2-hash literal → need 3 hashes
        #expect(hashCount(for: ###"contains \##n newline"###) == 3)
    }
}

// MARK: - Combined

extension Test_Primitives.Test.Snapshot.Inline.Rewriter.Test.HashCount {

    @Test
    func `triple Quote And Backslash Hash Take Maximum`() {
        // """ needs 1, \#( needs 2 → max is 2
        let content = ##"has """ and \#(x)"##
        #expect(hashCount(for: content) == 2)
    }

    @Test
    func `triple Quote Hash And Backslash Take Maximum`() {
        // """# needs 2, \ needs 1 → max is 2
        let content = ##"has """# and \"##
        #expect(hashCount(for: content) == 2)
    }
}
