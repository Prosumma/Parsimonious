//
//  CountS.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func countS(from: Int, to: Int, _ parser: @escaping ParserS) -> ParserS {
    return joined <*> count(from: from, to: to, parser)
}

public func countS(from: Int, to: Int, _ test: @escaping (Character) -> Bool) -> ParserS {
    return countS(from: from, to: to, satisfyChar(test))
}

public func countS(from: Int, to: Int, _ test: CharacterTest) -> ParserS {
    return countS(from: from, to: to, satisfyChar(test))
}

public func countS(from: Int, to: Int, any tests: [CharacterTest]) -> ParserS {
    return countS(from: from, to: to, satisfyChar(any: tests))
}

public func countS(from: Int, to: Int, any tests: CharacterTest...) -> ParserS {
    return countS(from: from, to: to, satisfyChar(any: tests))
}

public func countS(from: Int, to: Int, all tests: [CharacterTest]) -> ParserS {
    return countS(from: from, to: to, satisfyChar(all: tests))
}

public func countS(from: Int, to: Int, all tests: CharacterTest...) -> ParserS {
    return countS(from: from, to: to, satisfyChar(all: tests))
}

public func countS(_ range: ClosedRange<Int>, _ parser: @escaping ParserS) -> ParserS {
    return countS(from: range.lowerBound, to: range.upperBound, parser)
}

public func countS(_ range: ClosedRange<Int>, _ test: @escaping (Character) -> Bool) -> ParserS {
    return countS(range, satisfyChar(test))
}

public func countS(_ range: ClosedRange<Int>, _ test: CharacterTest) -> ParserS {
    return countS(range, satisfyChar(test))
}

public func countS(_ range: ClosedRange<Int>, any tests: [CharacterTest]) -> ParserS {
    return countS(range, satisfyChar(any: tests))
}

public func countS(_ range: ClosedRange<Int>, any tests: CharacterTest...) -> ParserS {
    return countS(range, satisfyChar(any: tests))
}

public func countS(_ range: ClosedRange<Int>, all tests: [CharacterTest]) -> ParserS {
    return countS(range, satisfyChar(all: tests))
}

public func countS(_ range: ClosedRange<Int>, all tests: CharacterTest...) -> ParserS {
    return countS(range, satisfyChar(all: tests))
}

public func countS(_ range: Range<Int>, _ parser: @escaping ParserS) -> ParserS {
    return countS(from: range.lowerBound, to: range.upperBound - 1, parser)
}

public func countS(_ range: Range<Int>, _ test: @escaping (Character) -> Bool) -> ParserS {
    return countS(range, satisfyChar(test))
}

public func countS(_ range: Range<Int>, _ test: CharacterTest) -> ParserS {
    return countS(range, satisfyChar(test))
}

public func countS(_ range: Range<Int>, any tests: [CharacterTest]) -> ParserS {
    return countS(range, satisfyChar(any: tests))
}

public func countS(_ range: Range<Int>, any tests: CharacterTest...) -> ParserS {
    return countS(range, satisfyChar(any: tests))
}

public func countS(_ range: Range<Int>, all tests: [CharacterTest]) -> ParserS {
    return countS(range, satisfyChar(all: tests))
}

public func countS(_ range: Range<Int>, all tests: CharacterTest...) -> ParserS {
    return countS(range, satisfyChar(all: tests))
}

public func countS(_ range: PartialRangeFrom<Int>, _ parser: @escaping ParserS) -> ParserS {
    return countS(from: range.lowerBound, to: Int.max, parser)
}

public func countS(_ range: PartialRangeFrom<Int>, _ test: @escaping (Character) -> Bool) -> ParserS {
    return countS(range, satisfyChar(test))
}

public func countS(_ range: PartialRangeFrom<Int>, _ test: CharacterTest) -> ParserS {
    return countS(range, satisfyChar(test))
}

public func countS(_ range: PartialRangeFrom<Int>, any tests: [CharacterTest]) -> ParserS {
    return countS(range, satisfyChar(any: tests))
}

public func countS(_ range: PartialRangeFrom<Int>, any tests: CharacterTest...) -> ParserS {
    return countS(range, satisfyChar(any: tests))
}

public func countS(_ range: PartialRangeFrom<Int>, all tests: [CharacterTest]) -> ParserS {
    return countS(range, satisfyChar(all: tests))
}

public func countS(_ range: PartialRangeFrom<Int>, all tests: CharacterTest...) -> ParserS {
    return countS(range, satisfyChar(all: tests))
}

public func countS(_ number: Int, _ parser: @escaping ParserS) -> ParserS {
    return countS(from: number, to: number, parser)
}

public func countS(_ number: Int, _ test: @escaping (Character) -> Bool) -> ParserS {
    return countS(number, satisfyChar(test))
}

public func countS(_ number: Int, _ test: CharacterTest) -> ParserS {
    return countS(number, satisfyChar(test))
}

public func countS(_ number: Int, any tests: [CharacterTest]) -> ParserS {
    return countS(number, satisfyChar(any: tests))
}

public func countS(_ number: Int, any tests: CharacterTest...) -> ParserS {
    return countS(number, satisfyChar(any: tests))
}

public func countS(_ number: Int, all tests: [CharacterTest]) -> ParserS {
    return countS(number, satisfyChar(all: tests))
}

public func countS(_ number: Int, all tests: CharacterTest...) -> ParserS {
    return countS(number, satisfyChar(all: tests))
}
