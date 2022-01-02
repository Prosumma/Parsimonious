//
//  CountS.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-04-11.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 Attempts to match `parser` at least `from` and at most `to` times. Matches a string.
 
 Direct use of this combinator should be avoided. Instead, use `manyS`, `many1S`, or one of the overloads that takes an `Int` or range type.
 
 - precondition: `from >= 0 && from <= to && to > 0`
 
 - parameter from: The minimum number of matches permitted.
 - parameter to: The maximum number of matches permitted.
 - parameter parser: The parser to match.
 
 - returns: A parser of type `ParserS` which matches a string of the matched type.
 */
public func countS(from: UInt, to: UInt, _ parser: @escaping ParserS) -> ParserS {
  joined <%> count(from: from, to: to, parser)
}


public func countS<R: RangeExpression>(_ range: R, _ parser: @escaping ParserS) -> ParserS where R.Bound == UInt {
  joined <%> count(range, parser)
}

public func countS<R: RangeExpression>(_ range: R, _ test: @escaping (Character) -> Bool) -> ParserS where R.Bound == UInt {
  countS(range, char(test))
}

public func countS<R: RangeExpression>(_ range: R, _ test: CharacterTest) -> ParserS where R.Bound == UInt {
  countS(range, char(test))
}

public func countS<R: RangeExpression>(_ range: R, any tests: [CharacterTest]) -> ParserS where R.Bound == UInt {
  countS(range, char(any: tests))
}

public func countS<R: RangeExpression>(_ range: R, any tests: CharacterTest...) -> ParserS where R.Bound == UInt {
  countS(range, char(any: tests))
}

public func countS<R: RangeExpression>(_ range: R, all tests: [CharacterTest]) -> ParserS where R.Bound == UInt {
  countS(range, char(all: tests))
}

public func countS<R: RangeExpression>(_ range: R, all tests: CharacterTest...) -> ParserS where R.Bound == UInt {
  countS(range, char(all: tests))
}

public func countS(_ number: UInt, _ parser: @escaping ParserS) -> ParserS {
  countS(from: number, to: number, parser)
}

public func countS(_ number: UInt, _ test: @escaping (Character) -> Bool) -> ParserS {
  countS(number, char(test))
}

public func countS(_ number: UInt, _ test: CharacterTest) -> ParserS {
  countS(number, char(test))
}

public func countS(_ number: UInt, any tests: [CharacterTest]) -> ParserS {
  countS(number, char(any: tests))
}

public func countS(_ number: UInt, any tests: CharacterTest...) -> ParserS {
  countS(number, char(any: tests))
}

public func countS(_ number: UInt, all tests: [CharacterTest]) -> ParserS {
  countS(number, char(all: tests))
}

public func countS(_ number: UInt, all tests: CharacterTest...) -> ParserS {
  countS(number, char(all: tests))
}
