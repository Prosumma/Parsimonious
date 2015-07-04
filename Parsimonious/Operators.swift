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

public func &<T>(lhs: ParseContext -> ParseResult<T>, rhs: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return and(lhs, rhs)
}

public func |<T>(lhs: ParseContext -> ParseResult<T>, rhs: ParseContext -> ParseResult<T>) -> ParseContext -> ParseResult<T> {
    return or(lhs, rhs)
}

public func <*<A, R>(lhs: A -> R, rhs: A) -> R {
    return lhs(rhs)
}

