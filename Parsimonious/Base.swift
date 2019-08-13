//
//  Base.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/10/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 Succeeds if the current element in the parsed collection is `==` to `model`.
 
 - parameter type: The type of the underlying collection. Can usually be inferred and thus omitted.
 - parameter model: The model element with which to compare the current element in the parsed collection.
 */
public func satisfy<C: Collection, E: Equatable>(type: C.Type = C.self, _ model: E) -> Parser<C, E> where E == C.Element {
    return satisfy(type: type, { $0 == model })
}

/**
 Expects `parser` to succeed `range` times. In other words, if `range` is `1...7`, then `parser` must match
 at least one and at most seven times.
 
 - parameter range: A closed range giving an inclusive range of times `parser` must match.
 - parameter parser: The parser to match.
 
 - returns: A parser giving an array of matches.
 */
public func count<C: Collection, T>(_ range: ClosedRange<Int>, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: range.lowerBound, to: range.upperBound, parser)
}

/**
 Expects `parser` to match `range` times. In other words, if `range` is `1..<8`, then `parser` must match
 at least one and at most seven times.
 
 - parameter range: An open range (excluding the upper bound) of times `parser` must match.
 - parameter parser: The parser to match.
 
 - returns: A parser giving an array of matches.
 */
public func count<C: Collection, T>(_ range: Range<Int>, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: range.lowerBound, to: range.upperBound - 1, parser)
}

/**
 Uses a partial range to match `parser` a minimum number of times. In other words, if range is `4...`, then `parser`
 must match at least 4 times.
 
 - parameter range: A partial range of times `parser` must match.
 - parameter parser: The parser to match.
 
 - returns: A parser giving an array of matches.
 */
public func count<C: Collection, T>(_ range: PartialRangeFrom<Int>, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: range.lowerBound, to: Int.max, parser)
}

/**
 Matches `parser` exactly `number` of times. In other words, `count(7, char("a"))` matches the letter "a" exactly 7 times.
 
 - parameter number: The exact number of times `parser` must match.
 - parameter parser: The parser to match.
 
 - returns: A parser giving an array of matches.
 */
public func count<C: Collection, T>(_ number: Int, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: number, to: number, parser)
}

public func many<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(0..., parser)
}

public func many<C: Collection, T, S>(_ parser: @escaping Parser<C, T>, sepBy separator: @escaping Parser<C, S>) -> Parser<C, [T]> {
    return optional(parser) & many(separator *> parser)
}

public func many1<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(1..., parser)
}

public func many1<C: Collection, T, S>(_ parser: @escaping Parser<C, T>, sepBy separator: @escaping Parser<C, S>) -> Parser<C, [T]> {
    return parser & many(separator *> parser)
}

/**
 Attempts to match at least one of the `parsers`. If none of the `parsers` succeeds,
 rethrows the last error.
 
 - note: It is usually more convenient to use the `|` combinator instead of this one. To have
 control over the error message, pass the `fail` combinator as the last parser. For example:
 
 ```
 let p = or(string("good"),
            string("bad"),
            fail("Should have matched good or bad!")
           )
 ```
 
 - parameter parsers: The array of parsers to match.
 - returns: A parser which matches at least one of the `parsers` or dies trying.
 */
public func or<C: Collection, T>(_ parsers: Parser<C, T>...) -> Parser<C, T> {
    return or(parsers)
}

/**
 Attempts to match at least one of the `parsers`. If none of the `parsers` succeeds,
 rethrows the last error.
 
 - note: It is usually more convenient to use the `|` combinator instead of this one. To have
 control over the error message, pass the `fail` combinator as the last parser. For example:
 
 ```
 let p = string("good") |
         string("bad") |
         fail("Shoud have matched good or bad!")
 ```
 
 - parameter parsers: The array of parsers to match.
 - returns: A parser which matches at least one of the `parsers` or dies trying.
 */
public func |<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, T>) -> Parser<C, T> {
    return or(lhs, rhs)
}

public func sequence<C: Collection, T>(_ parsers: Parser<C, T>...) -> Parser<C, [T]> {
    return sequence(parsers)
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, [T]>, rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T>, rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T?>, rhs: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, [T]>, rhs: @escaping Parser<C, T?>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

public func &<C: Collection, T>(lhs: @escaping Parser<C, T?>, rhs: @escaping Parser<C, [T]>) -> Parser<C, [T]> {
    return sequence(lhs, rhs)
}

public func <*><C: Collection, I, O>(lhs: @escaping (I) -> O, rhs: @escaping Parser<C, I>) -> Parser<C, O> {
    return lift(lhs, rhs)
}

public func subst<C: Collection, I, O>(_ value: O, _ parser: @escaping Parser<C, I>) -> Parser<C, O> {
    return {_ in value} <*> parser
}

public func <=><C: Collection, I, O>(lhs: O, rhs: @escaping Parser<C, I>) -> Parser<C, O> {
    return subst(lhs, rhs)
}

public func not<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, Void> {
    return { context in
        try context <- peek(parser)
        throw ParseError(message: "Negative lookahead failed.", context: context)
    }
}

public prefix func !<C: Collection, T>(parser: @escaping Parser<C, T>) -> Parser<C, Void> {
    return not(parser)
}

public func <*<C: Collection, L, R>(lparser: @escaping Parser<C, L>, rparser: @escaping Parser<C, R>) -> Parser<C, L> {
    return first(lparser, rparser)
}

public func *><C: Collection, L, R>(lparser: @escaping Parser<C, L>, rparser: @escaping Parser<C, R>) -> Parser<C, R> {
    return second(lparser, rparser)
}

/**
 Unconditionally consumes the next element in the underlying collection. Fails only
 on EOF.
 
 - throws: `ParseError` on EOF
 - parameter context: The context wrapping the consumed collection.
 - returns: The consumed element.
 */
public func accept<C: Collection>(_ context: Context<C>) throws -> C.Element {
    return try context <- satisfy{ _ in true }
}

