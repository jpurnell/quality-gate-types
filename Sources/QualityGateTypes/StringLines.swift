import Foundation

/// Splitting text into lines, correctly, in one place.
///
/// Moved here from `QualityGateCore` on 2026-09-18. It was reached transitively by
/// `quality-gate-dashboard`, which broke the moment that package stopped depending on the
/// static-analysis one — a general string utility was quietly part of the gate's public
/// surface. It carries no gate or corpus semantics, and both packages already share this
/// one, so it belongs here. `QualityGateCore` re-exports this module, so every existing
/// call site is unchanged.
extension StringProtocol {

    /// The text split into lines, however the file that produced it terminated them.
    ///
    /// ## Why this is not a one-liner at each call site
    ///
    /// There are three obvious ways to split text into lines in Swift and all three are wrong
    /// on a file written on Windows, each differently:
    ///
    /// | Written as | `"a\r\nb"` becomes |
    /// | --- | --- |
    /// | `split(separator: "\n")` | `["a\r\nb"]` — the whole document, one element |
    /// | `components(separatedBy: "\n")` | `["a\r", "b"]` — a stray return on every line |
    /// | `components(separatedBy: .newlines)` | `["a", "", "b"]` — an empty line per CRLF |
    ///
    /// `"\r\n"` is a single `Character` — one extended grapheme cluster. `split(separator:)`
    /// compares whole `Character`s and so never matches it. `components(separatedBy: String)`
    /// searches by scalar and finds the `\n` inside, leaving the `\r` behind.
    /// `CharacterSet.newlines` contains both scalars and counts them as two separators.
    ///
    /// The third is the one that catches people fixing the first two, and it is the worst of
    /// them for an auditor: doubling a file's line count shifts every line number reported
    /// against it, so a diagnostic points at the wrong line.
    ///
    /// `Character.isNewline` is true of CR, LF, CRLF, NEL, and the Unicode line and paragraph
    /// separators, and a CRLF is one `Character` — so this splits each of them exactly once.
    ///
    /// Empty subsequences are kept, so a blank line stays a blank line and indexing by line
    /// number behaves as `components(separatedBy:)` did.
    public var lines: [String] {
        // Through a concrete `String` rather than splitting `Self` directly: on `StringProtocol`
        // the overload is ambiguous, and the one that would resolve over unicode scalars splits
        // a CRLF twice — the very thing this exists to prevent.
        let text = String(self)
        return text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map(String.init)
    }
}
