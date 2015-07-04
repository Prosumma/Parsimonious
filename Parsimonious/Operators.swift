//
//  Operators.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

infix operator <* {
    associativity right
    precedence 255
}

infix operator *> {
    associativity left
    precedence 50
}

infix operator ! {
    associativity left
    precedence 50
}

postfix operator * {}
postfix operator + {}

public func &<T>(lhs: ParseContext -> ParseResult<T>, rhs: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return and(lhs, rhs)
}

public func |<T>(lhs: ParseContext -> ParseResult<T>, rhs: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return or(lhs, rhs)
}

public func <*<A, R>(lhs: A -> R, rhs: A) -> R {
    return lhs(rhs)
}

public func *><T1, T2>(lhs: ParseContext -> ParseResult<T1>, rhs: [(T1, String.Index)] -> [(T2, String.Index)]) -> ParseContext -> ParseResult<T2> {
    return lift(lhs, transform: rhs)
}

public func *><T1, T2>(lhs: ParseContext -> ParseResult<T1>, rhs: T1 -> T2) -> ParseContext -> ParseResult<T2> {
    return lift(lhs, transform: rhs)
}

public func !<T>(lhs: ParseContext -> ParseResult<T>, rhs: ErrorType) -> ParseContext -> ParseResult<T> {
    return expect(lhs, error: rhs)
}

public prefix func !<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return not <* parser
}

public postfix func *<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return many <* parser
}

public postfix func +<T>(parser: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return some <* many <* parser
}

