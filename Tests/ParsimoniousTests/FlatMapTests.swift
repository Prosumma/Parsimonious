//
//  FlatMapTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

struct FlatMapTests {
  /// A length prefix such as `3:`.
  static let count = char(anyOf: "0123456789")+.toString().map { Int($0)! } <* char(":")

  /// Takes exactly `n` characters, whatever they are.
  static func take(_ n: Int) -> Parser<String, String> {
    Parser { (input) throws(ParseError<String>) in
      guard let end = input.index(input.startIndex, offsetBy: n, limitedBy: input.endIndex) else {
        throw ParseError(reason: .eof, slice: input, message: "Expected \(n) characters.")
      }
      return .init(input: input[end...], output: String(input[..<end]))
    }
  }

  // A netstring: the length decides how much is taken, so the content may contain ":" or ",".
  static let netstring = count.flatMap { n in take(n) } <* char(",")

  // MARK: - flatMap returning a parser

  @Test func nextParserDependsOnOutput() throws {
    let result = try Self.netstring.parse("3:a:b,!")
    #expect(result.output == "a:b")
    #expect(result.input == "!")
  }

  @Test func zeroLength() throws {
    let result = try Self.netstring.parse("0:,")
    #expect(result.output == "")
    #expect(result.input == "")
  }

  @Test func multiStatementClosure() throws {
    // `just` can't infer `Input` from an opaque return type, so the closure states it.
    let p = Self.count.flatMap { n -> Parser<String, String> in
      if n == 0 {
        return just("empty")
      }
      return Self.take(n)
    }
    #expect(try p.parse("0:").output == "empty")
    #expect(try p.parse("2:hi").output == "hi")
  }

  @Test func characterArrayInput() throws {
    // The second character must be the successor of the first.
    let p: Parser<[Character], Character> = char("a").flatMap { c in
      char(Character(Unicode.Scalar(c.unicodeScalars.first!.value + 1)!))
    }
    let result = try p.parse(Array("abc"))
    #expect(result.output == "b")
    #expect(Array(result.input) == ["c"])
  }

  @Test func firstParserFailureFallsThrough() throws {
    let p = Self.netstring.commit1() <|> just("fallback")
    #expect(try p.parse("x").output == "fallback")
  }

  @Test func nextParserFailureKeepsItsSlice() {
    let error = #expect(throws: ParseError<String>.self) {
      try Self.netstring.parse("5:ab,")
    }
    #expect(error?.reason == .eof)
    #expect(error.map { String($0.slice) } == "ab,")
    #expect(error?.message == "Expected 5 characters.")
  }

  @Test func nextParserFailureIsCommitted() {
    // The length prefix was consumed, so `commit1()` commits.
    let p = Self.netstring.commit1() <|> just("fallback")
    let error = #expect(throws: ParseError<String>.self) {
      try p.parse("2:abc,")
    }
    #expect(error?.committed == true)
    #expect(error?.message == "Expected \",\".")
  }

  // MARK: - flatMap over ParseOutput

  static let shortNetstring = count.flatMap { (output) throws(ParseError<String>) in
    guard output.output <= 3 else {
      throw ParseError(reason: .nomatch, slice: output.input[..<output.input.startIndex], message: "Too long.")
    }
    return try take(output.output).parse(output.input)
  }

  @Test func parseOutputOverloadParsesRemainder() throws {
    let result = try Self.shortNetstring.parse("2:hi!")
    #expect(result.output == "hi")
    #expect(result.input == "!")
  }

  @Test func parseOutputOverloadCanThrow() {
    let input = "9:abcdefghi"
    let error = #expect(throws: ParseError<String>.self) {
      try Self.shortNetstring.parse(input)
    }
    #expect(error?.reason == .nomatch)
    #expect(error?.message == "Too long.")
    #expect(error.map { input.distance(from: input.startIndex, to: $0.slice.startIndex) } == 2)
  }

  @Test func parseOutputOverloadExpectingRelabelsFirstFailure() {
    let error = #expect(throws: ParseError<String>.self) {
      try Self.shortNetstring.expecting("Expected a netstring.").parse("x")
    }
    #expect(error?.message == "Expected a netstring.")
  }
}
