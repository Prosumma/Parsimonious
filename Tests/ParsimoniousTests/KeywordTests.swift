//
//  KeywordTests.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-16.
//

import Parsimonious
import Testing

struct KeywordTests {
  enum Keyword: String, CaseIterable, Sendable {
    case `in`, int, `let`
  }

  @Test(arguments: Keyword.allCases)
  func matchesEveryCase(_ k: Keyword) throws {
    let result = try keyword(Keyword.self).parse(k.rawValue + "!")
    #expect(result.output == k)
    #expect(result.input == "!")
  }

  @Test func triesLongestFirst() throws {
    // "in" is declared first, but "int" is longer, so it's tried first.
    #expect(try keyword(Keyword.self).parse("int").output == .int)
    let result = try keyword(Keyword.self).parse("in x")
    #expect(result.output == .in)
    #expect(result.input == " x")
  }

  @Test func doesNotCheckWordBoundary() throws {
    let result = try keyword(Keyword.self).parse("integer")
    #expect(result.output == .int)
    #expect(result.input == "eger")
  }

  @Test func wordBoundaryWithNot() {
    let kw = keyword(Keyword.self) <* char(\.isLetter).not()
    #expect(throws: ParseError<String>.self) {
      try kw.parse("integer")
    }
  }

  @Test func failureListsCasesInDeclarationOrder() {
    let error = #expect(throws: ParseError<String>.self) {
      try keyword(Keyword.self).parse("var")
    }
    #expect(error?.reason == .nomatch)
    #expect(error?.message == "Expected one of \"in\", \"int\", \"let\".")
    #expect(error.map { String($0.slice) } == "")
    #expect(error?.committed == false)
  }

  @Test func partialMatchFailsWithSameMessage() {
    // "le" starts "let", but the failure comes from `or`, so it isn't committed.
    let error = #expect(throws: ParseError<String>.self) {
      try keyword(Keyword.self).parse("lex")
    }
    #expect(error?.message == "Expected one of \"in\", \"int\", \"let\".")
    #expect(error?.committed == false)
  }

  @Test func backtracksInsideOr() throws {
    let p = keyword(Keyword.self).map { $0.rawValue } <|> string("lex")
    #expect(try p.parse("lex").output == "lex")
  }

  @Test func simpleMatching() throws {
    let result = try keyword(Keyword.self, matching: .simple).parse("LET")
    #expect(result.output == .let)
  }

  @Test func defaultsToExact() {
    #expect(throws: ParseError<String>.self) {
      try keyword(Keyword.self).parse("LET")
    }
  }

  @Test func infersStringInputWithoutContext() {
    let kw = keyword(Keyword.self)
    #expect(type(of: kw) == Parser<String, Keyword>.self)
  }

  @Test func characterArrayInput() throws {
    let input = Array("int!")
    let result = try keyword(Keyword.self).parse(input)
    #expect(result.output == .int)
    #expect(Array(result.input) == ["!"])
  }
}
