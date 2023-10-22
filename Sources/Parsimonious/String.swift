//
//  String.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-20.
//

extension String: Defaultable {
  public static let defaultValue: String = ""
}

extension Parser: ExpressibleByUnicodeScalarLiteral where Source.Element == Character, Output == String {
  public init(unicodeScalarLiteral value: String) {
    self = string(value)
  }
}

extension Parser: ExpressibleByExtendedGraphemeClusterLiteral where Source.Element == Character, Output == String {
  public init(extendedGraphemeClusterLiteral value: String) {
    self = string(value)
  }
}

extension Parser: ExpressibleByStringLiteral where Source.Element == Character, Output == String {
  public init(stringLiteral value: String) {
    self = string(value)
  }
}

public postfix func * <C: Collection>(
  _ parser: @escaping @autoclosure () -> Parser<C, String>
) -> Parser<C, String> {
  manyS(parser())
}

public postfix func + <C: Collection>(
  _ parser: @escaping @autoclosure () -> Parser<C, String>
) -> Parser<C, String> {
  many1S(parser())
}

public extension Parser where Output == Character {
  func joined() -> Parser<Source, String> {
    map { String($0) }
  }
}

public extension Parser where Output == [Character] {
  func joined() -> Parser<Source, String> {
    map { String($0) }
  }
}

public extension Parser where Output == [String] {
  func joined(separator: String = "") -> Parser<Source, String> {
    map { $0.joined(separator: separator) }
  }
}

public func + <C: Collection>(
  lhs: @escaping @autoclosure () -> Parser<C, String>,
  rhs: @escaping @autoclosure () -> Parser<C, String>
) -> Parser<C, String> {
  lhs() >>= { a in
    rhs() >>> { b in
      a + b
    }
  }
}

public func + <C: Collection>(
  lhs: @escaping @autoclosure () -> Parser<C, Character>,
  rhs: @escaping @autoclosure () -> Parser<C, String>
) -> Parser<C, String> {
  lhs().joined() + rhs()
}

public func + <C: Collection>(
  lhs: @escaping @autoclosure () -> Parser<C, String>,
  rhs: @escaping @autoclosure () -> Parser<C, Character>
) -> Parser<C, String> {
  lhs() + rhs().joined()
}

/// Matches any single character, but not EOF.
public func char<C: Collection>() -> Parser<C, String> where C.Element == Character {
  match().joined()
}

public func char<C: Collection>(
  _ test: @escaping (Character) -> Bool
) -> Parser<C, String> where C.Element == Character {
  match(test).joined()
}

public func char<C: Collection>(
  any tests: [(Character) -> Bool]
) -> Parser<C, String> where C.Element == Character {
  match(any: tests).joined()
}

public func char<C: Collection>(
  any tests: ((Character) -> Bool)...
) -> Parser<C, String> where C.Element == Character {
  char(any: tests)
}

public func char<C: Collection>(
  any tests: [KeyPath<Character, Bool>]
) -> Parser<C, String> where C.Element == Character {
  let test: (KeyPath<Character, Bool>) -> (Character) -> Bool = { keyPath in {
    $0[keyPath: keyPath]
  }}
  return char(any: tests.map(test))
}

public func char<C: Collection>(
  any tests: KeyPath<Character, Bool>...
) -> Parser<C, String> where C.Element == Character {
  char(any: tests)
}

public func char<C: Collection>(
  _ model: @escaping @autoclosure () -> Character
) -> Parser<C, String> where C.Element == Character {
  char { $0 == model() }
}

public func char<C: Collection>(
  any models: [Character]
) -> Parser<C, String> where C.Element == Character {
  char { models.contains($0) }
}

public func char<C: Collection>(
  any models: Character...
) -> Parser<C, String> where C.Element == Character {
  char(any: models)
}

public func char<C: Collection>(
  any string: String
) -> Parser<C, String> where C.Element == Character {
  char(any: Array(string))
}

public func string<C: Collection>(
  _ model: @escaping @autoclosure () -> String
) -> Parser<C, String> where C.Element == Character {
  chain(model().map { char($0) }).joined()
}

public func manyS<C: Collection>(
  _ parser: @escaping @autoclosure () -> Parser<C, String>
) -> Parser<C, String> {
  many(parser()).joined()
}

public func many1S<C: Collection>(
  _ parser: @escaping @autoclosure () -> Parser<C, String>
) -> Parser<C, String> {
  many1(parser()).joined()
}

public extension Parser where Source.Element == Character {
  static var whitespace: Parser<Source, String> {
    char(\.isWhitespace)
  }
  
  static var newline: Parser<Source, String> {
    char(\.isNewline)
  }

  static var doubleStraightQuote: Parser<Source, String> {
    char("\"")
  }
  
  static var singleStraightQuote: Parser<Source, String> {
    char("'")
  }
}

public func whitespaced<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> where C.Element == Character {
  delimit(parser(), by: many(.whitespace))
}

public func whitespacedWithNewlines<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> where C.Element == Character {
  delimit(parser(), by: many(.whitespace <|> .newline))
}

public func parenthesized<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> where C.Element == Character {
  delimit(parser(), by: char("("), and: char(")"))
}

/**
 - Warning: Does *not* handle escaping. You will
 have to do that yourself.
 */
public func doubleStraightQuoted<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> where C.Element == Character {
  delimit(parser(), by: .doubleStraightQuote)
}

/**
 - Warning: Does *not* handle escaping. You will
 have to do that yourself.
 */
public func singleStraightQuoted<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> where C.Element == Character {
  delimit(parser(), by: .singleStraightQuote)
}

public func bracketed<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> where C.Element == Character {
  delimit(parser(), by: char("["), and: char("]"))
}

public func braced<C: Collection, T>(
  _ parser: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, T> where C.Element == Character {
  delimit(parser(), by: char("{"), and: char("}"))
}
