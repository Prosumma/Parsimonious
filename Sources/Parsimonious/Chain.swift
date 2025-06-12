//
//  Chain.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-25.
//

import Foundation

/**
 Aggregates the result of all the parsers into an array.
 
 Most of the time, it's more convenient to use the more polymorphic
 `+` operator.
 
 - Note: This is Haskell's `sequence`, but less general, and with
 a Swiftier name.
 */
public func chain<C: Collection, T>(
  _ parsers: @escaping @Sendable @autoclosure () -> [Parser<C, T>]
) -> Parser<C, [T]> {
  reduce([], parsers()) { array, item in array + [item] }
}

/**
 Aggregates the result of all the parsers into an array.
 
 - Note: This is Haskell's `sequence`, but less general, and with
 a Swiftier name.
 */
public func chain<C: Collection, T>(
  _ parsers: Parser<C, T>...
) -> Parser<C, [T]> {
  chain(parsers)
}

public func + <C: Collection, T>(
  lhs: @escaping @Sendable @autoclosure () -> Parser<C, [T]>,
  rhs: @escaping @Sendable @autoclosure () -> Parser<C, [T]>
) -> Parser<C, [T]> {
  zip(lhs(), rhs()) { $0 + $1 }
}

public func + <C: Collection, T>(
  lhs: @escaping @Sendable @autoclosure () -> Parser<C, T>,
  rhs: @escaping @Sendable @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  chain(lhs(), rhs())
}

public func + <C: Collection, T>(
  lhs: @escaping @Sendable @autoclosure () -> Parser<C, T>,
  rhs: @escaping @Sendable @autoclosure () -> Parser<C, [T]>
) -> Parser<C, [T]> {
  lhs().list() + rhs()
}

public func + <C: Collection, T>(
  lhs: @escaping @Sendable @autoclosure () -> Parser<C, [T]>,
  rhs: @escaping @Sendable @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  lhs() + rhs().list()
}
