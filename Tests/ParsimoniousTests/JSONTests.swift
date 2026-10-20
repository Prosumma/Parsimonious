//
//  JSONTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

enum JSON: Sendable, Equatable {
  case number(String)
  case string(String)
  case array([JSON])
  case object([String: JSON])
  case bool(Bool)
  case null
}

extension JSON: ExpressibleByIntegerLiteral {
  init(integerLiteral value: Int) {
    self = .number("\(value)")
  }
}

extension JSON: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: JSON...) {
    self = .array(elements)
  }
}

extension JSON: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (String, JSON)...) {
    var object: [String: JSON] = [:]
    for (key, value) in elements {
      object[key] = value
    }
    self = .object(object)
  }
}

extension JSON: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension JSON: ExpressibleByBooleanLiteral {
  init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension JSON: ExpressibleByNilLiteral {
  init(nilLiteral: ()) {
    self = .null
  }
}

// JSON's grammar is defined on Unicode scalars, so it's parsed with scalar parsers wherever
// possible. A `Character` can join a structural scalar to a combining mark after it: `"` and
// U+0301 are one Character, and `char("\"")` can't match it.

// MARK: - Whitespace

// JSON allows only these four as whitespace, while `whitespaced()` accepts any Unicode
// whitespace. At the scalar level, "\r\n" is simply "\r" followed by "\n".
let jws = scalar(anyOf: " \t\n\r")*

extension Parsing where Input == String {
  func jsonWhitespaced() -> Parser<String, Output> {
    delimited(by: jws)
  }
}

let comma = scalar(",").jsonWhitespaced()
let colon = scalar(":").jsonWhitespaced()

/// Like `many(separatedBy: comma)`, except that an element must follow each comma. Without the
/// commit, `[1,]` backtracks over the trailing comma and reports `Expected "]".` at the comma
/// rather than a missing value after it.
func list<Output>(of element: Parser<String, Output>) -> Parser<String, [Output]> {
  join(element.array(), (comma *> element).commit1()*) <|> just([])
}

// MARK: - Literals

// There's no scalar version of `string`. A literal followed by a combining mark fails either
// way, since nothing in JSON can follow a value without whitespace or punctuation.
let jnull = string("null").commit1().map { JSON.null }
// Each alternative commits separately: `or` discards uncommitted errors, so committing the
// `or` as a whole would never fire.
let jbool =
  string("true").commit1().map { JSON.bool(true) }
  <|> string("false").commit1().map { JSON.bool(false) }

// MARK: - Strings

let backslash = scalar("\\")
let hexDigit = scalar(anyOf: "0123456789abcdefABCDEF").expecting("Expected a hex digit.")
// Only the digits are committed: `\n` also starts with a backslash, so failing on the `u`
// has to backtrack.
let codeUnit =
  backslash *> scalar("u") *> hexDigit.count(4).toString().map { UInt16($0, radix: 16)! }.commit()
// Consecutive escapes are decoded together, so a surrogate pair becomes one scalar. A lone
// surrogate can't be stored in a String, so it becomes U+FFFD.
let unicodeEscapes = codeUnit+.map { String(decoding: $0, as: UTF16.self) }
let escape = (backslash *> scalar(anyOf: "\"\\/bfnrt").expecting("Expected an escape sequence."))
  .commit1()
  .map { s -> String in
    switch s {
    case "b": "\u{8}"
    case "f": "\u{C}"
    case "n": "\n"
    case "r": "\r"
    case "t": "\t"
    default: String(s)
    }
  }
// Anything but a quote, a backslash or a control character.
let unescaped = scalar { $0.value >= 0x20 && $0 != "\"" && $0 != "\\" }
let jidentifier = (unescaped+.toString() <|> unicodeEscapes <|> escape)*
  .map { $0.joined() }
  .doubleStraightQuoted()
  .commit1()
let jstring = jidentifier.map { JSON.string($0) }

// MARK: - Numbers

// `isNumber` and `isHexDigit` accept non-ASCII digits, which JSON doesn't.
let digit = scalar(anyOf: "0123456789").expecting("Expected a digit.")
let integer = (scalar("0").array() <|> join(scalar(anyOf: "123456789").array(), digit*))
  .expecting("Expected a digit.")
let fraction = join(scalar(".").array(), digit+).commit1()
let exponent = join(scalar(anyOf: "eE").array(), scalar(anyOf: "+-").optional(), digit+).commit1()
let jnumber = join(scalar("-").optional(), integer, fraction <|> just([]), exponent <|> just([]))
  .toString()
  .commit1()
  .map { JSON.number($0) }

// MARK: - Arrays and objects

let jarray = list(of: jelem.jsonWhitespaced())
  .jsonWhitespaced()
  .bracketed()
  .commit1()
  .map { JSON.array($0) }
let member = tuple(jidentifier.expecting("Expected a string."), colon *> jelem.jsonWhitespaced())
  .commit1()
// Duplicate keys are allowed, and the last one wins.
let jobject = list(of: member)
  .jsonWhitespaced()
  .braced()
  .commit1()
  .map { JSON.object(Dictionary($0) { _, last in last }) }

// MARK: - Values

let jvalue = (jnull <|> jbool <|> jstring <|> jnumber <|> jarray <|> jobject)
  .expecting("Expected a JSON value.")
let jelem: Parser<String, JSON> = Parser { (input) throws(ParseError<String>) in
  try jvalue.parse(input)
}
let json = jelem.jsonWhitespaced().end()

// MARK: - Tests

struct JSONTests {
  struct Failure: Sendable, CustomTestStringConvertible {
    let input: String
    let message: String
    let line: Int
    let column: Int

    init(_ input: String, _ message: String, at column: Int, line: Int = 1) {
      self.input = input
      self.message = message
      self.line = line
      self.column = column
    }

    var testDescription: String { input.debugDescription }
  }

  func error(parsing input: String) -> ParseError<String>? {
    #expect(throws: ParseError<String>.self) {
      try parse(input, with: json)
    }
  }

  // MARK: Literals

  @Test func literals() throws {
    #expect(try parse("null", with: json) == nil)
    #expect(try parse("true", with: json) == true)
    #expect(try parse("false", with: json) == false)
  }

  @Test(arguments: ["nul", "tru", "fals", "True", "NULL", "nullx", "truefalse"])
  func invalidLiterals(_ input: String) {
    _ = error(parsing: input)
  }

  @Test func partialLiteralIsCommitted() {
    let error = error(parsing: "tru")
    #expect(error?.committed == true)
    #expect(error?.message == "Expected \"true\".")
  }

  // MARK: Numbers

  @Test(arguments: [
    "0", "-0", "7", "-7", "10", "1234567890",
    "0.5", "-0.5", "3.14159", "10.01",
    "1e5", "1E5", "1e+5", "1e-5", "1E-05", "0e0", "-0.0e-0", "6.02214076e23",
    // Kept as written, so precision isn't lost.
    "123456789012345678901234567890", "0.1000000000000000055511151231257827",
  ])
  func validNumbers(_ input: String) throws {
    #expect(try parse(input, with: json) == .number(input))
  }

  @Test(arguments: [
    "01", "-01", "00", "+1", ".5", "-.5", "1.", "1.e5", "1e", "1e+", "1E-", "--1", "-",
    "0x10", "1.5.5", "1e5.5", "Infinity", "-Infinity", "NaN",
    // Non-ASCII digits: fullwidth and Arabic-Indic.
    "\u{FF11}", "\u{0661}",
  ])
  func invalidNumbers(_ input: String) {
    _ = error(parsing: input)
  }

  @Test func numberInsideArray() throws {
    #expect(try parse("[0,-1.5e3]", with: json) == [0, .number("-1.5e3")])
  }

  // MARK: Strings

  @Test(arguments: [
    (#""""#, ""),
    (#""abc""#, "abc"),
    (#""a b""#, "a b"),
    (#""\"\\\/\b\f\n\r\t""#, "\"\\/\u{8}\u{C}\n\r\t"),
    (#""a/b""#, "a/b"),
    (#""\u0041""#, "A"),
    (#""\u00e9\u00E9""#, "éé"),
    (#""\u0000""#, "\u{0}"),
    (#""x\u0041y\u0042z""#, "xAyBz"),
    // A surrogate pair, decoded from consecutive escapes.
    (#""\uD83D\uDE00""#, "😀"),
    (#""\ud83d\ude00!""#, "😀!"),
    // Lone surrogates become U+FFFD.
    (#""\uDE00""#, "\u{FFFD}"),
    (#""\uD83Dx""#, "\u{FFFD}x"),
    (#""\uD83D\uD83D\uDE00""#, "\u{FFFD}😀"),
    // An escaped combining mark joins the previous character.
    (#""e\u0301""#, "é"),
    ("\"日本語 😀\"", "日本語 😀"),
    // DEL isn't a control character as far as JSON is concerned.
    ("\"\u{7F}\"", "\u{7F}"),
    // A raw combining mark joins the opening quote, or the last character of an escape, to
    // make one Character. Only a scalar parser can separate them.
    ("\"\u{301}abc\"", "\u{301}abc"),
    ("\"\u{301}\"", "\u{301}"),
    ("\"\\n\u{301}\"", "\n\u{301}"),
    ("\"\\\"\u{301}\"", "\"\u{301}"),
    ("\"\\u0041\u{301}\"", "Á"),
    // A raw combining mark after an unescaped character.
    ("\"a\u{301}\"", "á"),
  ])
  func validStrings(_ input: String, _ expected: String) throws {
    #expect(try parse(input, with: json) == .string(expected))
  }

  @Test(arguments: [
    #""abc"#,
    #"""#,
    #""\""#,
    #"'abc'"#,
    #""\x""#,
    #""\U0041""#,
    #""\u12""#,
    #""\u12G4""#,
    #""\u""#,
    // Fullwidth hex digits.
    "\"\\u\u{FF10}\u{FF10}\u{FF14}\u{FF11}\"",
    // Unescaped control characters.
    "\"a\tb\"",
    "\"a\nb\"",
    "\"a\r\nb\"",
    "\"a\u{0}b\"",
    "\"a\u{1F}b\"",
    // A combining mark after the closing quote is outside the string.
    "\"a\"\u{301}\"",
    "\"a\"\u{301}",
    // A combining mark isn't an escape character.
    "\"\\\u{301}\"",
  ])
  func invalidStrings(_ input: String) {
    _ = error(parsing: input)
  }

  @Test func combiningMarksInsideStructure() throws {
    let input = "{\"\u{301}\": [\"\u{301}\", \"\u{303}x\"]}"
    #expect(try parse(input, with: json) == ["\u{301}": ["\u{301}", "\u{303}x"]])
  }

  @Test(arguments: [
    // After structural punctuation, a combining mark makes one Character with it, but it's
    // still a separate scalar that JSON doesn't allow there.
    "[\u{301}]", "[1,\u{301}2]", "{\"a\":\u{301}1}", "1\u{301}", "-\u{301}1", "1.\u{301}5",
    "null\u{301}", " \u{301}1",
  ])
  func combiningMarksOutsideStrings(_ input: String) {
    _ = error(parsing: input)
  }

  @Test func objectKeysAreUnescaped() throws {
    #expect(try parse(#"{"\u0061\n": 1}"#, with: json) == ["a\n": 1])
  }

  // MARK: Arrays

  @Test func emptyArrays() throws {
    #expect(try parse("[]", with: json) == [])
    #expect(try parse("[ ]", with: json) == [])
    #expect(try parse("[\n\t]", with: json) == [])
  }

  @Test func arrays() throws {
    #expect(try parse("[1]", with: json) == [1])
    #expect(try parse("[1,2,3]", with: json) == [1, 2, 3])
    #expect(try parse(" [ 1 , 2 , 3 ] ", with: json) == [1, 2, 3])
    #expect(
      try parse(#"[null, true, "x", 1, [], {}]"#, with: json) == [nil, true, "x", 1, [], [:]])
  }

  @Test func nestedArrays() throws {
    #expect(try parse("[[],[[]],[[1]]]", with: json) == [[], [[]], [[1]]])
  }

  @Test(arguments: ["[", "]", "[1", "[1,", "[1,]", "[,1]", "[,]", "[1 2]", "[1,,2]", "[1]]"])
  func invalidArrays(_ input: String) {
    _ = error(parsing: input)
  }

  // MARK: Objects

  @Test func emptyObjects() throws {
    #expect(try parse("{}", with: json) == [:])
    #expect(try parse("{ }", with: json) == [:])
    #expect(try parse("{\r\n}", with: json) == [:])
  }

  @Test func objects() throws {
    #expect(try parse(#"{"a":1}"#, with: json) == ["a": 1])
    #expect(try parse(#"{ "a" : 1 , "b" : [ 2 ] }"#, with: json) == ["a": 1, "b": [2]])
    #expect(try parse(#"{"":null}"#, with: json) == ["": nil])
  }

  @Test func nestedObjects() throws {
    #expect(try parse(#"{"a":{"b":{"c":{}}}}"#, with: json) == ["a": ["b": ["c": [:]]]])
  }

  @Test func duplicateKeysLastWins() throws {
    #expect(try parse(#"{"a":1,"a":2}"#, with: json) == ["a": 2])
  }

  @Test(arguments: [
    "{", "}", #"{"a""#, #"{"a":"#, #"{"a":1"#, #"{"a"}"#, #"{"a" 1}"#, #"{"a":}"#,
    #"{"a":1,}"#, #"{,}"#, #"{"a":1 "b":2}"#, #"{a:1}"#, #"{'a':1}"#, #"{1:1}"#, #"{null:1}"#,
  ])
  func invalidObjects(_ input: String) {
    _ = error(parsing: input)
  }

  // MARK: Whitespace

  @Test func jsonWhitespace() throws {
    #expect(try parse(" \t\n\r[ \t\n\r1 \t\n\r] \t\n\r", with: json) == [1])
  }

  @Test func crlfIsWhitespace() throws {
    // "\r\n" is one Character, but two scalars that are each JSON whitespace.
    #expect(try parse("[\r\n1,\r\n2\r\n]\r\n", with: json) == [1, 2])
  }

  @Test(arguments: [
    "\u{A0}",  // no-break space
    "\u{B}",  // vertical tab
    "\u{C}",  // form feed
    "\u{85}",  // next line
    "\u{2028}",  // line separator
    "\u{3000}",  // ideographic space
  ])
  func otherWhitespaceIsRejected(_ ws: String) {
    _ = error(parsing: "[1,\(ws)2]")
    _ = error(parsing: "\(ws)1")
  }

  // MARK: Top level

  @Test(arguments: ["null", "true", "1", "\"s\"", "[]", "{}"])
  func anyValueAtTopLevel(_ input: String) throws {
    _ = try parse(" \(input) ", with: json)
  }

  @Test(arguments: ["", " ", "1 2", "[] []", "{}x", "null null"])
  func exactlyOneValue(_ input: String) {
    _ = error(parsing: input)
  }

  @Test func deepNesting() throws {
    // Each level costs roughly 18KB of stack in a debug build, and Swift Testing runs tests on
    // threads with 512KB stacks, so not much deeper than this fits.
    let depth = 20
    let input = String(repeating: "[", count: depth) + String(repeating: "]", count: depth)
    var expected: JSON = []
    for _ in 1..<depth {
      expected = [expected]
    }
    #expect(try parse(input, with: json) == expected)
  }

  @Test func document() throws {
    let input = """
      {
        "name": "Parsimonious",
        "version": "3.0.0",
        "tags": ["parser", "combinator", "swift"],
        "stars": 1.5e3,
        "license": { "name": "MIT", "osi": true },
        "parent": null,
        "escapes": "tab\\there \\u2603",
        "empty": [{}, [], ""]
      }
      """
    let expected: JSON = [
      "name": "Parsimonious",
      "version": "3.0.0",
      "tags": ["parser", "combinator", "swift"],
      "stars": .number("1.5e3"),
      "license": ["name": "MIT", "osi": true],
      "parent": nil,
      "escapes": "tab\there ☃",
      "empty": [[:], [], ""],
    ]
    #expect(try parse(input, with: json) == expected)
  }

  // MARK: Errors

  @Test(arguments: [
    Failure("", "Expected a JSON value.", at: 1),
    Failure("x", "Expected a JSON value.", at: 1),
    Failure("tru", "Expected \"true\".", at: 4),
    Failure("[true, nul]", "Expected \"null\".", at: 11),
    Failure("-", "Expected a digit.", at: 2),
    Failure("-x", "Expected a digit.", at: 2),
    Failure("1.", "Expected a digit.", at: 3),
    Failure("1.x", "Expected a digit.", at: 3),
    Failure("1e+", "Expected a digit.", at: 4),
    Failure("01", "Expected end of input", at: 2),
    Failure("1 2", "Expected end of input", at: 3),
    Failure(#""abc"#, #"Expected """."#, at: 5),
    Failure("\"a\tb\"", #"Expected """."#, at: 3),
    Failure(#""\x""#, "Expected an escape sequence.", at: 3),
    Failure(#""\u12G4""#, "Expected a hex digit.", at: 6),
    Failure(#""\u12""#, "Expected a hex digit.", at: 6),
    Failure("[1,]", "Expected a JSON value.", at: 4),
    Failure("[1 , ]", "Expected a JSON value.", at: 6),
    Failure("[1 2]", #"Expected "]"."#, at: 4),
    Failure("[1", #"Expected "]"."#, at: 3),
    Failure(#"{"a" 1}"#, #"Expected ":"."#, at: 6),
    Failure(#"{"a":}"#, "Expected a JSON value.", at: 6),
    Failure(#"{"a":1,}"#, "Expected a string.", at: 8),
    Failure(#"{"a":1 "b":2}"#, #"Expected "}"."#, at: 8),
    Failure("{\n  \"a\": [1, 2,]\n}", "Expected a JSON value.", at: 14, line: 2),
    // The error is between "," and U+0301, which are one Character, so it's counted as one column.
    Failure("[1,\u{301}]", "Expected a JSON value.", at: 4),
    Failure("\"\\\u{301}\"", "Expected an escape sequence.", at: 3),
  ])
  func errorMessagesAndLocations(_ failure: Failure) {
    let error = error(parsing: failure.input)
    #expect(error?.message == failure.message)
    #expect(error?.location(in: failure.input) ?? (0, 0) == (failure.line, failure.column))
  }

  @Test(arguments: [#"{"a" 1}"#, "[1,]", #""\x""#, "-x", "[true, nul]"])
  func errorsInsideValuesAreCommitted(_ input: String) {
    #expect(error(parsing: input)?.committed == true)
  }
}
