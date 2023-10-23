//
//  StringTests.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 2023-10-21.
//

import Parsimonious
import XCTest

class StringTests: XCTestCase {
  func testChar() throws {
    // Given
    let parser: SParser = match(2, char()).joined() <* eof()
    
    // When
    let output = try parse("ax", with: parser)
    
    // Then
    XCTAssertEqual(output, "ax")
  }
  
  func testJoinedCharacterArray() throws {
    // Given
    let parser: SParser = match(2, match()).joined() <* eof()
    
    // When
    let output = try parse("ax", with: parser)
    
    // Then
    XCTAssertEqual(output, "ax")
  }
  
  func testAddCharacterAndString() throws {
    // Given
    let parser: SParser = (match() + char()) <* eof()
    
    // When
    let output = try parse("xy", with: parser)
    
    // Then
    XCTAssertEqual(output, "xy")
  }
  
  func testAddStringAndCharacter() throws {
    // Given
    let parser: SParser = (char() + match()) <* eof()
    
    // When
    let output = try parse("xy", with: parser)
    
    // Then
    XCTAssertEqual(output, "xy")
  }
  
  func testCharAnyKeyPaths() throws {
    // Given
    let parser: SParser = char(any(\Character.isLetter, \Character.isPunctuation))+ <* eof()

    // When
    let output = try parse("!c?T", with: parser)

    // Then
    XCTAssertEqual(output, "!c?T")
  }
  
  func testCharAnyModels() throws {
    // Given
    let parser: SParser = char(any("a", "e", "i"))* <* eof()
    
    // When
    let output = try parse("iiiaaaeeeie", with: parser)
    
    // Then
    XCTAssertEqual(output, "iiiaaaeeeie")
  }
  
  func testParenthesizedSingleStraightQuoted() throws {
    // Given
    let parser: SParser = whitespaced(parenthesized(singleStraightQuoted(char(any: "foo")*))) <* eof()
    
    // When
    let output = try parse("  ('foo')  ", with: parser)
    
    // Then
    XCTAssertEqual("foo", output)
  }
}
