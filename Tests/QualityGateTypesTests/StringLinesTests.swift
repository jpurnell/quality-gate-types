import Testing
@testable import QualityGateTypes

/// `lines` exists because the three obvious ways to split text are each wrong on a file
/// written on Windows, and each differently. These pin that table, so a "simplification"
/// back to any of them fails here rather than in a line number reported against a file.
@Suite("StringProtocol.lines")
struct StringLinesTests {

    @Test("CRLF splits exactly once — the case all three obvious spellings get wrong")
    func crlfSplitsOnce() {
        #expect("a\r\nb".lines == ["a", "b"])
    }

    // A test asserting what each wrong spelling returns was written here and removed: it has
    // to *call* `split(separator: "\n")`, `components(separatedBy: "\n")` and
    // `components(separatedBy: .newlines)` to demonstrate them, and those three calls are
    // exactly what `safety`'s `newline-split` rule forbids. The gate rejected it, correctly —
    // a demonstration of banned code is still banned code, and the table in the doc comment
    // already records the three results. The assertions below pin the behaviour that matters:
    // whatever the alternatives do, `lines` splits each terminator exactly once.

    @Test("LF and CR alone each split once")
    func singleTerminators() {
        #expect("a\nb".lines == ["a", "b"])
        #expect("a\rb".lines == ["a", "b"])
    }

    @Test("Blank lines are kept, so indexing by line number still works")
    func blankLinesSurvive() {
        #expect("a\n\nb".lines == ["a", "", "b"])
        #expect("a\n\nb".lines.count == 3)
    }

    @Test("A trailing newline yields a trailing empty element, as components did")
    func trailingNewline() {
        #expect("a\n".lines == ["a", ""])
    }

    @Test("Text with no terminator is one line; empty text is one empty line")
    func degenerateCases() {
        #expect("a".lines == ["a"])
        #expect("".lines == [""])
    }

    @Test("Unicode line and paragraph separators split too")
    func unicodeSeparators() {
        #expect("a\u{2028}b".lines == ["a", "b"])
        #expect("a\u{2029}b".lines == ["a", "b"])
    }

    @Test("Works through a Substring, not just String")
    func throughSubstring() {
        let text = "xa\r\nbx"
        let middle = text.dropFirst().dropLast()
        #expect(middle.lines == ["a", "b"])
    }
}
