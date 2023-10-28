//
//  ParseErrorTests.swift
//  ParsimoniousTests
//
//  Created by Greg Higley on 2023-10-22.
//

import XCTest
@testable import Parsimonious

class ParseErrorTests: XCTestCase {
  func testThrowParseErrorToResult() {
    let s = ""
    let result: Result<Void, ParseError<String>> = throwToResult(s.startIndex) {
      throw ParseError<String>(reason: .nomatch, index: s.startIndex)
    }
    guard
      case .failure(let error) = result,
      case .nomatch = error.reason
    else {
      return XCTFail("Expected failure but succeeded.")
    }
  }

  func testThrowErrorToResult() {
    let s = ""
    let result: Result<Void, ParseError<String>> = throwToResult(s.startIndex) {
      throw TestError.oops
    }
    guard
      case .failure(let error) = result,
      case .error(TestError.oops) = error.reason
    else {
      return XCTFail("Expected failure but succeeded.")
    }
  }
}
