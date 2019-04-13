//
//  Base.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/10/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func count<C: Collection, T>(_ range: ClosedRange<Int>, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: range.lowerBound, to: range.upperBound, parser)
}

public func count<C: Collection, T>(_ range: Range<Int>, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: range.lowerBound, to: range.upperBound - 1, parser)
}

public func count<C: Collection, T>(_ range: PartialRangeFrom<Int>, _ parser: @escaping Parser<C, T>) -> Parser<C, [T]> {
    return count(from: range.lowerBound, to: Int.max, parser)
}

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

public func or<C: Collection, T>(_ parsers: Parser<C, T>...) -> Parser<C, T> {
    return or(parsers)
}

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
        let value = try? context <- peek(parser)
        if value != nil {
            // Need a better error message for this, but what?
            throw ParseError(message: "Negative lookahead failed.", context: context)
        }
    }
}

public prefix func !<C: Collection, T>(parser: @escaping Parser<C, T>) -> Parser<C, Void> {
    return not(parser)
}

public func <*<C: Collection, L, R>(lparser: @escaping Parser<C, L>, rparser: @escaping Parser<C, R>) -> Parser<C, L> {
    return left(lparser, rparser)
}

public func *><C: Collection, L, R>(lparser: @escaping Parser<C, L>, rparser: @escaping Parser<C, R>) -> Parser<C, R> {
    return right(lparser, rparser)
}

public func eof<C: Collection>(_ context: Context<C>) throws {
    if !context.atEnd {
        let next = context.next!
        throw ParseError(message: "Expected EOF, but got \(next).", context: context)
    }
}

public func accept<C: Collection>(_ context: Context<C>) throws -> C.Element {
    return try context <- satisfy{ _ in true }
}

