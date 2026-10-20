//
//  Scalars.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

// Parsers that consume a single Unicode scalar from a `String` or `Substring`, rather than a
// whole `Character`. Use them where a grammar is defined on code points, as most machine
// formats are: a quote followed by a combining mark is one `Character`, so `char("\"")`
// can't match it, but `scalar("\"")` can. They mix freely with `char` and `string`, which
// see whatever follows a scalar as a new character, even partway through a grapheme.
//
// Unlike `Character`, scalars aren't compared by canonical equivalence: `scalar("é")` doesn't
// match `e` followed by U+0301. Normalize the input first if that matters.

/// Matches the single scalar `s` at the start of the input.
public func scalar<Input>(_ s: Unicode.Scalar) -> Parser<Input, Unicode.Scalar>
where Input.SubSequence == Substring {
  Parsers<Input>.scalar(s)
}

/// The `String` specialization of `scalar(_:)`, which lets `Input` be inferred
/// when there is no other context, as in `let quote = scalar("\"")`.
public func scalar(_ s: Unicode.Scalar) -> Parser<String, Unicode.Scalar> {
  Parsers<String>.scalar(s)
}

/// Matches any one of the scalars in `choices` at the start of the input.
/// If `choices` is empty, this never matches.
public func scalar<Input>(anyOf choices: String) -> Parser<Input, Unicode.Scalar>
where Input.SubSequence == Substring {
  Parsers<Input>.scalar(anyOf: choices)
}

/// The `String` specialization of `scalar(anyOf:)`, which lets `Input` be inferred
/// when there is no other context, as in `let digit = scalar(anyOf: "0123456789")`.
public func scalar(anyOf choices: String) -> Parser<String, Unicode.Scalar> {
  Parsers<String>.scalar(anyOf: choices)
}

/// Matches any single scalar at the start of the input except `s`. Fails at the end of the input.
public func scalar<Input>(not s: Unicode.Scalar) -> Parser<Input, Unicode.Scalar>
where Input.SubSequence == Substring {
  Parsers<Input>.scalar(not: s)
}

/// The `String` specialization of `scalar(not:)`, which lets `Input` be inferred
/// when there is no other context, as in `let notQuote = scalar(not: "\"")`.
public func scalar(not s: Unicode.Scalar) -> Parser<String, Unicode.Scalar> {
  Parsers<String>.scalar(not: s)
}

/// Matches a single scalar for which `keyPath` is `true`, as in `scalar(\.properties.isDiacritic)`.
///
/// Has no message of its own; add one with `expecting(_:)`.
public func scalar<Input>(_ keyPath: any KeyPath<Unicode.Scalar, Bool> & Sendable) -> Parser<
  Input, Unicode.Scalar
> where Input.SubSequence == Substring {
  Parsers<Input>.scalar(where: { $0[keyPath: keyPath] })
}

/// The `String` specialization of `scalar(_:)`, which lets `Input` be inferred
/// when there is no other context, as in `let mark = scalar(\.properties.isDiacritic)`.
public func scalar(_ keyPath: any KeyPath<Unicode.Scalar, Bool> & Sendable) -> Parser<
  String, Unicode.Scalar
> {
  Parsers<String>.scalar(where: { $0[keyPath: keyPath] })
}

/// Matches a single scalar for which `keyPath` is `false`, as in `scalar(not: \.properties.isWhitespace)`.
///
/// Has no message of its own; add one with `expecting(_:)`.
public func scalar<Input>(not keyPath: any KeyPath<Unicode.Scalar, Bool> & Sendable) -> Parser<
  Input, Unicode.Scalar
> where Input.SubSequence == Substring {
  Parsers<Input>.scalar(where: { !$0[keyPath: keyPath] })
}

/// The `String` specialization of `scalar(not:)`, which lets `Input` be inferred
/// when there is no other context, as in `let visible = scalar(not: \.properties.isWhitespace)`.
public func scalar(not keyPath: any KeyPath<Unicode.Scalar, Bool> & Sendable) -> Parser<
  String, Unicode.Scalar
> {
  Parsers<String>.scalar(where: { !$0[keyPath: keyPath] })
}

/// Matches a single scalar for which `test` is `true`. This is `satisfy` for scalars, since
/// `satisfy` sees a `String` as `Character`s.
///
/// Has no message of its own; add one with `expecting(_:)`.
public func scalar<Input>(where test: @Sendable @escaping (Unicode.Scalar) -> Bool) -> Parser<
  Input, Unicode.Scalar
> where Input.SubSequence == Substring {
  Parsers<Input>.scalar(where: test)
}

/// The `String` specialization of `scalar(where:)`, which lets `Input` be inferred
/// when there is no other context, as in `let ascii = scalar(where: \.isASCII)`.
public func scalar(where test: @Sendable @escaping (Unicode.Scalar) -> Bool) -> Parser<
  String, Unicode.Scalar
> {
  Parsers<String>.scalar(where: test)
}

/// Quotes a scalar that's visible on its own, as `"a"`, and names any other by its code point,
/// as `U+0301`. A combining mark or a control character inside quotes can't be seen.
private func describe(_ s: Unicode.Scalar) -> String {
  switch s.properties.generalCategory {
  case .control, .format, .surrogate, .privateUse, .unassigned,
    .spaceSeparator, .lineSeparator, .paragraphSeparator,
    .nonspacingMark, .spacingMark, .enclosingMark:
    let hex = String(s.value, radix: 16, uppercase: true)
    return "U+" + String(repeating: "0", count: max(0, 4 - hex.count)) + hex
  default:
    return "\"\(s)\""
  }
}

// The `String` overloads can't call the generic ones directly, because overload resolution
// would pick themselves.
extension Parsers where Input.SubSequence == Substring {
  fileprivate static func scalar(_ s: Unicode.Scalar) -> Parser<Input, Unicode.Scalar> {
    scalar(where: { $0 == s }, message: "Expected \(describe(s)).")
  }

  fileprivate static func scalar(anyOf choices: String) -> Parser<Input, Unicode.Scalar> {
    let set = Set(choices.unicodeScalars)
    let names = choices.unicodeScalars.map(describe).joined(separator: ", ")
    return scalar(where: { set.contains($0) }, message: "Expected one of \(names).")
  }

  fileprivate static func scalar(not s: Unicode.Scalar) -> Parser<Input, Unicode.Scalar> {
    scalar(where: { $0 != s }, message: "Expected any scalar except \(describe(s)).")
  }

  fileprivate static func scalar(
    where matches: @Sendable @escaping (Unicode.Scalar) -> Bool,
    message: String? = nil
  ) -> Parser<Input, Unicode.Scalar> {
    Parser { (input) throws(ParseError<Input>) in
      guard let first = input.unicodeScalars.first else {
        throw ParseError(reason: .eof, slice: input, message: message)
      }
      guard matches(first) else {
        throw ParseError(reason: .nomatch, slice: input[..<input.startIndex], message: message)
      }
      let next = input.unicodeScalars.index(after: input.startIndex)
      return .init(input: input[next...], output: first)
    }
  }
}

extension Parsing where Output == Unicode.Scalar {
  public func toString() -> Parser<Input, String> {
    array().toString()
  }
}

extension Parsing where Output == [Unicode.Scalar] {
  public func toString() -> Parser<Input, String> {
    map { String(String.UnicodeScalarView($0)) }
  }
}
