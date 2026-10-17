//
//  Strings.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-05.
//

import Foundation

/// How `string(_:matching:)` compares letter case.
public enum CaseMatching: Sendable {
  /// Characters must be identical: `a` ≠ `A`, `ß` ≠ `ss`.
  case exact
  /// Each character matches exactly one character, ignoring case: `a` == `A`, but `ß` ≠ `ss`.
  /// Locale-independent, so dotless `ı` stays distinct from `I`.
  case simple
  /// Full Unicode case folding: `ß` == `ss`. The matched text may differ in length from the pattern.
  case folded
}

/// Matches the single character `ch` at the start of the input.
///
/// Always consumes exactly one character. With `.folded`, that character is compared
/// using full case folding, so `ς` matches `σ`, but `ß` never consumes the two characters `ss`.
/// The output is the character as it appears in the input.
public func char<Input>(
  _ ch: Character,
  matching: CaseMatching = .exact
) -> Parser<Input, Character> where Input.Element == Character {
  Parsers<Input>.char(ch, matching: matching)
}

/// The `String` specialization of `char(_:matching:)`, which lets `Input` be inferred
/// when there is no other context, as in `let a = char("a")`.
public func char(_ ch: Character, matching: CaseMatching = .exact) -> Parser<String, Character> {
  Parsers<String>.char(ch, matching: matching)
}

/// Matches any one of the characters in `choices` at the start of the input.
///
/// Each choice is compared as `char(_:matching:)` would compare it. The output is the
/// character as it appears in the input. If `choices` is empty, this never matches.
public func char<Input>(
  anyOf choices: String,
  matching: CaseMatching = .exact
) -> Parser<Input, Character> where Input.Element == Character {
  Parsers<Input>.char(anyOf: choices, matching: matching)
}

/// The `String` specialization of `char(anyOf:matching:)`, which lets `Input` be inferred
/// when there is no other context, as in `let vowel = char(anyOf: "aeiou")`.
public func char(anyOf choices: String, matching: CaseMatching = .exact) -> Parser<String, Character> {
  Parsers<String>.char(anyOf: choices, matching: matching)
}

/// Matches any single character at the start of the input except `ch`.
///
/// `ch` is compared as `char(_:matching:)` would compare it, so with `.simple` or `.folded`,
/// `char(not: "a")` rejects `A` too. Fails at the end of the input.
public func char<Input>(
  not ch: Character,
  matching: CaseMatching = .exact
) -> Parser<Input, Character> where Input.Element == Character {
  Parsers<Input>.char(not: ch, matching: matching)
}

/// The `String` specialization of `char(not:matching:)`, which lets `Input` be inferred
/// when there is no other context, as in `let notQuote = char(not: "'")`.
public func char(not ch: Character, matching: CaseMatching = .exact) -> Parser<String, Character> {
  Parsers<String>.char(not: ch, matching: matching)
}

/// Matches a single character for which `keyPath` is `true`, as in `char(\.isLetter)`.
///
/// Has no message of its own; add one with `expecting(_:)`.
///
/// `Character` properties come from the first scalar, so `\.isWhitespace` is also true for a
/// space followed by a combining mark. Use `Parsers.whitespace` to match whitespace.
public func char<Input>(_ keyPath: any KeyPath<Character, Bool> & Sendable) -> Parser<Input, Character> where Input.Element == Character {
  Parsers<Input>.char(keyPath)
}

/// The `String` specialization of `char(_:)`, which lets `Input` be inferred
/// when there is no other context, as in `let letter = char(\.isLetter)`.
public func char(_ keyPath: any KeyPath<Character, Bool> & Sendable) -> Parser<String, Character> {
  Parsers<String>.char(keyPath)
}

/// Matches a single character for which `keyPath` is `false`, as in `char(not: \.isWhitespace)`.
///
/// Has no message of its own; add one with `expecting(_:)`.
public func char<Input>(not keyPath: any KeyPath<Character, Bool> & Sendable) -> Parser<Input, Character> where Input.Element == Character {
  Parsers<Input>.char(not: keyPath)
}

/// The `String` specialization of `char(not:)`, which lets `Input` be inferred
/// when there is no other context, as in `let nonSpace = char(not: \.isWhitespace)`.
public func char(not keyPath: any KeyPath<Character, Bool> & Sendable) -> Parser<String, Character> {
  Parsers<String>.char(not: keyPath)
}

/// Matches the literal `s` at the start of the input.
///
/// The output is the matched text as it appears in the input, which differs from `s`
/// when `matching` ignores case.
public func string<Input>(
  _ s: String,
  matching: CaseMatching = .exact
) -> Parser<Input, String> where Input.Element == Character {
  Parsers<Input>.string(s, matching: matching)
}

/// The `String` specialization of `string(_:matching:)`, which lets `Input` be inferred
/// when there is no other context, as in `let blah = string("blah")`.
public func string(_ s: String, matching: CaseMatching = .exact) -> Parser<String, String> {
  Parsers<String>.string(s, matching: matching)
}

/// Matches the raw value of any case of `K`, and outputs that case.
///
/// Longer raw values are tried first, so with cases `in` and `int`, the input `int` matches
/// `int`. Each raw value is compared as `string(_:matching:)` would compare it.
///
/// This doesn't check what follows the match, so on `integer` the cases above match `int`.
/// To require a word boundary, add one: `keyword(K.self) <* char(\.isLetter).not()`.
@_disfavoredOverload
public func keyword<Input, K>(
  _: K.Type,
  matching: CaseMatching = .exact
) -> Parser<Input, K> where Input.Element == Character, K: CaseIterable & RawRepresentable & Sendable, K.RawValue == String {
  Parsers<Input>.keyword(K.self, matching: matching)
}

/// The `String` specialization of `keyword(_:matching:)`, which lets `Input` be inferred
/// when there is no other context, as in `let kw = keyword(Keyword.self)`.
public func keyword<K>(
  _: K.Type,
  matching: CaseMatching = .exact
) -> Parser<String, K> where K: CaseIterable & RawRepresentable & Sendable, K.RawValue == String {
  Parsers<String>.keyword(K.self, matching: matching)
}

private func expected(_ s: String) -> String {
  "Expected \"\(s)\"."
}

// The public `char` and `string` overloads both delegate here. The `String` overloads
// can't call the generic ones directly, because overload resolution would pick themselves.
private extension Parsers where Input.Element == Character {
  static func char(_ ch: Character, matching: CaseMatching) -> Parser<Input, Character> {
    char(where: predicate(for: ch, matching), message: expected(String(ch)))
  }

  static func char(anyOf choices: String, matching: CaseMatching) -> Parser<Input, Character> {
    let predicates = choices.map { predicate(for: $0, matching) }
    return char(
      where: { c in predicates.contains { $0(c) } },
      message: "Expected one of \"\(choices)\"."
    )
  }

  static func char(not ch: Character, matching: CaseMatching) -> Parser<Input, Character> {
    let matches = predicate(for: ch, matching)
    return char(where: { !matches($0) }, message: "Expected any character except \"\(ch)\".")
  }

  static func char(
    where matches: @Sendable @escaping (Character) -> Bool,
    message: String
  ) -> Parser<Input, Character> {
    Parser { (input) throws(ParseError<Input>) in
      guard let first = input.first else {
        throw ParseError(reason: .eof, slice: input, message: message)
      }
      let next = input.index(after: input.startIndex)
      guard matches(first) else {
        throw ParseError(reason: .nomatch, slice: input[..<input.startIndex], message: message)
      }
      return .init(input: input[next...], output: first)
    }
  }

  static func char(
    _ keyPath: any KeyPath<Character, Bool> & Sendable
  ) -> Parser<Input, Character> {
    satisfy { $0[keyPath: keyPath] }
  }

  static func char(
    not keyPath: any KeyPath<Character, Bool> & Sendable
  ) -> Parser<Input, Character> {
    satisfy { !$0[keyPath: keyPath] }
  }

  static func predicate(for ch: Character, _ matching: CaseMatching) -> @Sendable (Character) -> Bool {
    switch matching {
    case .exact:
      return { $0 == ch }
    case .simple:
      let lowered = ch.lowercased()
      return { $0.lowercased() == lowered }
    case .folded:
      let target = String(ch)
      return { String($0).compare(target, options: .caseInsensitive) == .orderedSame }
    }
  }

  static func keyword<K>(
    _: K.Type,
    matching: CaseMatching
  ) -> Parser<Input, K> where K: CaseIterable & RawRepresentable & Sendable, K.RawValue == String {
    let names = K.allCases.map { "\"\($0.rawValue)\"" }.joined(separator: ", ")
    let longestFirst = K.allCases.sorted { $0.rawValue.count > $1.rawValue.count }
    let parsers = longestFirst.map { k in string(k.rawValue, matching: matching).map { _ in k } }
    return or(parsers).expecting("Expected one of \(names).")
  }

  static func string(_ s: String, matching: CaseMatching) -> Parser<Input, String> {
    // `.simple` lowercases the pattern once here rather than on every comparison.
    let lowered = matching == .simple ? s.map { $0.lowercased() } : []
    return Parser { (input) throws(ParseError<Input>) in
      let end: Input.Index
      switch matching {
      case .exact:
        end = try matchEnd(of: s, as: s, in: input, by: ==)
      case .simple:
        end = try matchEnd(of: s, as: lowered, in: input) { $0 == $1.lowercased() }
      case .folded:
        end = try foldedMatchEnd(of: s, in: input)
      }
      return .init(input: input[end...], output: String(input[..<end]))
    }
  }

  /// Matches `pattern`, one element per input character, and reports failures as failing to match `s`.
  static func matchEnd<Pattern: Sequence>(
    of s: String,
    as pattern: Pattern,
    in input: Input.SubSequence,
    by equal: (Pattern.Element, Character) -> Bool
  ) throws(ParseError<Input>) -> Input.Index {
    var current = input.startIndex
    for c in pattern {
      guard current < input.endIndex else {
        throw ParseError(reason: .eof, slice: input, message: expected(s))
      }
      guard equal(c, input[current]) else {
        throw ParseError(reason: .nomatch, slice: input[..<current], message: expected(s))
      }
      current = input.index(after: current)
    }
    return current
  }

  static func foldedMatchEnd(of s: String, in input: Input.SubSequence) throws(ParseError<Input>) -> Input.Index {
    if s.isEmpty {
      return input.startIndex
    }
    // Full case folding maps a scalar to at most three scalars, so a match can't
    // span more characters than this. Searching a bounded window keeps Foundation
    // from bridging the entire remaining input on every attempt.
    let window = input.prefix(s.unicodeScalars.count * 3)
    let text = String(window)
    let options: String.CompareOptions = [.anchored, .caseInsensitive]
    if let range = text.range(of: s, options: options) {
      // Map the end of the match back into the input by counting scalars rather than
      // characters: building a String can merge characters, e.g. a lone combining mark
      // in a [Character].
      var remaining = text.unicodeScalars[..<range.upperBound].count
      var end = input.startIndex
      while remaining > 0 && end < input.endIndex {
        remaining -= input[end].unicodeScalars.count
        end = input.index(after: end)
      }
      // A match that ends partway through an input character isn't a match.
      if remaining == 0 {
        return end
      }
    }
    // The input ran out partway through a match, e.g. "stra" against "STRASSE".
    if window.endIndex == input.endIndex && (window.isEmpty || s.range(of: text, options: options) != nil) {
      throw ParseError(reason: .eof, slice: input, message: expected(s))
    }
    // The slice is the longest prefix of the input that still matches a prefix of `s`.
    var matched = window.count
    while matched > 0 && s.range(of: String(window.prefix(matched)), options: options) == nil {
      matched -= 1
    }
    throw ParseError(reason: .nomatch, slice: window.prefix(matched), message: expected(s))
  }
}

// Delimiters are matched as single scalars, not Characters. A delimiter followed by a combining
// mark is one Character, as with `"` and U+0301 at the start of a quoted string, which `char("\"")`
// can't match. A scalar leaves the mark for the parser that follows.
public extension Parsing where Input.SubSequence == Substring {
  func preceded(by s: Unicode.Scalar) -> Parser<Input, Output> {
    scalar(s) *> self
  }
  func followed(by s: Unicode.Scalar) -> Parser<Input, Output> {
    self <* scalar(s)
  }
  func delimited(by s: Unicode.Scalar) -> Parser<Input, Output> {
    delimited(by: scalar(s))
  }
  func delimited(by first: Unicode.Scalar, and last: Unicode.Scalar) -> Parser<Input, Output> {
    delimited(by: scalar(first), and: scalar(last))
  }
  func singleStraightQuoted() -> Parser<Input, Output> {
    delimited(by: "'")
  }
  func doubleStraightQuoted() -> Parser<Input, Output> {
    delimited(by: "\"")
  }
  func parenthesized() -> Parser<Input, Output> {
    delimited(by: "(", and: ")")
  }
  func bracketed() -> Parser<Input, Output> {
    delimited(by: "[", and: "]")
  }
  func braced() -> Parser<Input, Output> {
    delimited(by: "{", and: "}")
  }
}

public extension Parsing where Input.Element == Character {
  func whitespaced() -> Parser<Input, Output> {
    delimited(by: Parsers.whitespace*)
  }
  func whitespaced1() -> Parser<Input, Output> {
    delimited(by: Parsers.whitespace+)
  }
}

public extension Parsing where Output == Character {
  func toString() -> Parser<Input, String> {
    array().toString()
  }
}

public extension Parsing where Output == [Character] {
  func toString() -> Parser<Input, String> {
    map { String($0) }
  }
}

public extension Parsers where Input.Element == Character {
  /// Matches a character made up entirely of whitespace, such as a space, a tab or `"\r\n"`.
  ///
  /// This is stricter than `char(\.isWhitespace)`. `Character.isWhitespace` looks only at the
  /// first scalar, so it's also true for a space followed by a combining mark, which is how
  /// Unicode writes a diacritic on its own. Treating that as whitespace would discard the mark.
  static var whitespace: Parser<Input, Character> {
    satisfy { $0.unicodeScalars.allSatisfy(\.properties.isWhitespace) }
      .expecting("Expected whitespace.")
  }
}
