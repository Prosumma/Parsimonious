//
//  CountS.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
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
public func countS(from: Int, to: Int, _ parser: @escaping ParserS) -> ParserS {
    return joined <%> count(from: from, to: to, parser)
}

public func countS(_ range: ClosedRange<Int>, _ parser: @escaping ParserS) -> ParserS {
    return countS(from: range.lowerBound, to: range.upperBound, parser)
}

public func countS(_ range: ClosedRange<Int>, _ test: @escaping (Character) -> Bool) -> ParserS {
    return countS(range, char(test))
}

public func countS(_ range: ClosedRange<Int>, _ test: CharacterTest) -> ParserS {
    return countS(range, char(test))
}

public func countS(_ range: ClosedRange<Int>, any tests: [CharacterTest]) -> ParserS {
    return countS(range, char(any: tests))
}

public func countS(_ range: ClosedRange<Int>, any tests: CharacterTest...) -> ParserS {
    return countS(range, char(any: tests))
}

public func countS(_ range: ClosedRange<Int>, all tests: [CharacterTest]) -> ParserS {
    return countS(range, char(all: tests))
}

public func countS(_ range: ClosedRange<Int>, all tests: CharacterTest...) -> ParserS {
    return countS(range, char(all: tests))
}

public func countS(_ range: Range<Int>, _ parser: @escaping ParserS) -> ParserS {
    return countS(from: range.lowerBound, to: range.upperBound - 1, parser)
}

public func countS(_ range: Range<Int>, _ test: @escaping (Character) -> Bool) -> ParserS {
    return countS(range, char(test))
}

public func countS(_ range: Range<Int>, _ test: CharacterTest) -> ParserS {
    return countS(range, char(test))
}

public func countS(_ range: Range<Int>, any tests: [CharacterTest]) -> ParserS {
    return countS(range, char(any: tests))
}

public func countS(_ range: Range<Int>, any tests: CharacterTest...) -> ParserS {
    return countS(range, char(any: tests))
}

public func countS(_ range: Range<Int>, all tests: [CharacterTest]) -> ParserS {
    return countS(range, char(all: tests))
}

public func countS(_ range: Range<Int>, all tests: CharacterTest...) -> ParserS {
    return countS(range, char(all: tests))
}

public func countS(_ range: PartialRangeFrom<Int>, _ parser: @escaping ParserS) -> ParserS {
    return countS(from: range.lowerBound, to: Int.max, parser)
}

public func countS(_ range: PartialRangeFrom<Int>, _ test: @escaping (Character) -> Bool) -> ParserS {
    return countS(range, char(test))
}

public func countS(_ range: PartialRangeFrom<Int>, _ test: CharacterTest) -> ParserS {
    return countS(range, char(test))
}

public func countS(_ range: PartialRangeFrom<Int>, any tests: [CharacterTest]) -> ParserS {
    return countS(range, char(any: tests))
}

public func countS(_ range: PartialRangeFrom<Int>, any tests: CharacterTest...) -> ParserS {
    return countS(range, char(any: tests))
}

public func countS(_ range: PartialRangeFrom<Int>, all tests: [CharacterTest]) -> ParserS {
    return countS(range, char(all: tests))
}

public func countS(_ range: PartialRangeFrom<Int>, all tests: CharacterTest...) -> ParserS {
    return countS(range, char(all: tests))
}

public func countS(_ number: Int, _ parser: @escaping ParserS) -> ParserS {
    return countS(from: number, to: number, parser)
}

public func countS(_ number: Int, _ test: @escaping (Character) -> Bool) -> ParserS {
    return countS(number, char(test))
}

public func countS(_ number: Int, _ test: CharacterTest) -> ParserS {
    return countS(number, char(test))
}

public func countS(_ number: Int, any tests: [CharacterTest]) -> ParserS {
    return countS(number, char(any: tests))
}

public func countS(_ number: Int, any tests: CharacterTest...) -> ParserS {
    return countS(number, char(any: tests))
}

public func countS(_ number: Int, all tests: [CharacterTest]) -> ParserS {
    return countS(number, char(all: tests))
}

public func countS(_ number: Int, all tests: CharacterTest...) -> ParserS {
    return countS(number, char(all: tests))
}
