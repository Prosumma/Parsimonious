//
//  CombinatorTests.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 2023-10-21.
//

import XCTest

@testable import Parsimonious

enum TestError: Error, Equatable {
  case oops
}

enum Token {
  case string(String)
  case number(Int)
}

/**
 Coverage for any combinators not already
 covered by other tests.
 */
class CombinatorTests: XCTestCase {
  func testFail() {
    // Given
    let parser: SParser = char("a") <|> fail(TestError.oops)

    // When/Then
    XCTAssertThrowsError(try parse("x", with: parser)) { error in
      guard
        let error = error as? ParseError<String>,
        case .error(TestError.oops) = error.reason
      else {
        return XCTFail("Got the wrong error.")
      }
    }
  }

  func testDeferred() throws {
    // Given
    let parser1: SParser = deferred { source, index in
      let output = source[index]
      return .success(.init(output: output, range: index..<source.index(after: index)))
    }.joined()
    let parser2: SParser = deferred(char("z"))

    // When
    let output = try parse("xz", with: chain(parser1, parser2).joined() <* eof())

    // Then
    XCTAssertEqual(output, "xz")
  }

  func testMatchAnyTests() throws {
    // Given
    let isA: (Character) -> Bool = { $0 == "a" }
    let isB: (Character) -> Bool = { $0 == "b" }
    let word: SParser = (match(any(isA, isB))+.joined())
    let parser: Parser<String, [String]> = many(word, separator: ",") <* eof()

    // When
    let output = try parse("a,bb,aaa,aba", with: parser)

    // Then
    XCTAssertEqual(output, ["a", "bb", "aaa", "aba"])
  }

  func testMatchModel() throws {
    // Given
    let parser: SParser = match(^"a").joined() <* eof()

    // When
    let output = try parse("a", with: parser)

    // Then
    XCTAssertEqual(output, "a")
  }

  func testMatchAnyModels() throws {
    let parser: Parser<[Int], [Int]> = match(any(1, 7))* <* eof()

    // When
    let output = try parse([1, 1, 7, 7, 1], with: parser)

    // Then
    XCTAssertEqual(output, [1, 1, 7, 7, 1])
  }

  func testAddElementsProducingArray() throws {
    let parser: Parser<[Int], [Int]> = (match(^1) + match(^7)) <* eof()

    // When
    let output = try parse([1, 7], with: parser)

    // Then
    XCTAssertEqual(output, [1, 7])
  }

  func testAddArrayAndElementProducingArray() throws {
    let parser: Parser<[Int], [Int]> = (match(^1)+ + match(^7)) <* eof()

    // When
    let output = try parse([1, 1, 1, 7], with: parser)

    // Then
    XCTAssertEqual(output, [1, 1, 1, 7])
  }

  func testMany1WithSeparator() throws {
    // Given
    let digit: Parser<[Int], Int> = match(any(1, 2, 3, 4, 5, 6, 7, 8, 9))
    let group: Parser<[Int], [Int]> = many1(digit)
    let sep: Parser<[Int], Int> = match(^0)
    let parser: Parser<[Int], [[Int]]> = many1(group, separator: sep) <* eof()

    // When
    let output = try parse([2, 3, 9, 0, 4, 3, 0, 2, 0, 1, 5, 8], with: parser)

    // Then
    XCTAssertEqual(output, [[2, 3, 9], [4, 3], [2], [1, 5, 8]])
  }

  func testSkip() throws {
    // Given
    let parser: SParser = chain(char("a")+, skip(eof())).joined()

    // When
    let output = try parse("aaa", with: parser)

    // Then
    XCTAssertEqual(output, "aaa")
  }

  func testPeek() throws {
    // Given
    let parser: SParser = ((char(!",")+ <* peek(",")) + char(",")) <* eof()

    // When
    let output = try parse("xyz,", with: parser)

    // Then
    XCTAssertEqual(output, "xyz,")
  }

  func testEofFailure() throws {
    // Given
    let parser: SParser = eof() *> char("x")

    // When
    XCTAssertThrowsError(try parse("x", with: parser)) { error in
      guard
        let error = error as? ParseError<String>,
        case .nomatch = error.reason
      else {
        return XCTFail("Expected not to match, but it matched.")
      }
    }
  }

  func testMatchInsufficiency() throws {
    // Given
    let parser: SParser = match(7, "a").joined() <* eof()

    // When
    XCTAssertThrowsError(try parse("aa", with: parser)) { error in
      guard
        let error = error as? ParseError<String>,
        case .eof = error.reason
      else {
        return XCTFail("Expected eof, but nope.")
      }
    }
  }

  func testNotTest() throws {
    // Given
    let n: (Int) -> Bool = not { $0 == 2 }

    // When/Then
    XCTAssertTrue(n(3))
  }

  func testNotAnyTests() throws {
    // Given
    let is2: (Int) -> Bool = { $0 == 2 }
    let is3: (Int) -> Bool = { $0 == 3 }
    let n = not((any(is2, is3)))

    // When/Then
    XCTAssertTrue(n(5))
  }

  func testNotAnyKeyPaths() throws {
    // Given
    let c = !any(\Character.isSymbol, \Character.isPunctuation)

    // When/Then
    XCTAssertTrue(c("a"))
  }

  func testNotAnyModels() throws {
    // Given
    let c = !any("x", "y")

    // When/Then
    XCTAssertTrue(c("a"))
  }

  func testNotAnyParsers() throws {
    // Given
    let parser: SParser = "a"+ <* not(any: "c", "e") <* eof()

    // When
    let output = try parse("a", with: parser)

    // Then
    XCTAssertEqual(output, "a")
  }

  func testNotAnyParsersFail() throws {
    // Given
    let parser: SParser = "a"+ <* not(any: "c", "e") <* eof()

    // When/Then
    XCTAssertThrowsError(try parse("ac", with: parser)) { error in
      guard
        let error = error as? ParseError<String>,
        case .nomatch = error.reason
      else {
        return XCTFail("Expected .nomatch, but it matched.")
      }
    }
  }

  func testExtract() throws {
    // Given
    let parser: Parser<[Token], String> = extract {
      guard case .string(let s) = $0 else {
        return nil
      }
      return s
    }
    let tokens = [Token.string("token")]

    // When
    let strings = try parse(tokens, with: many(parser) <* eof())

    // Then
    XCTAssertEqual(strings, ["token"])
  }

  func testExtractThrows() throws {
    // Given
    let parser: Parser<[Token], String> = extract {
      guard case .string(let s) = $0 else {
        return nil
      }
      return s
    }
    let tokens = [Token.number(3)]

    // When/Then
    XCTAssertThrowsError(try parse(tokens, with: many(parser) <* eof())) { error in
      guard
        let error = error as? ParseError<[Token]>,
        case .nomatch = error.reason
      else {
        return XCTFail("Expected not to match.")
      }
    }

  }
}
