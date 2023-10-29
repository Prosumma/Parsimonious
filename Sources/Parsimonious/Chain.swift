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
  _ parsers: @escaping @autoclosure () -> [Parser<C, T>]
) -> Parser<C, [T]> {
  .init { source, index in
    var outputs: [T] = []
    var index = index
    var result: ParseResult<C, [T]> = .success(.init(output: outputs, range: index..<index))
    PARSE: for parser in parsers() {
      switch parser(source, at: index) {
      case .success(let state):
        outputs.append(state.output)
        result = .success(.init(output: outputs, range: index..<state.range.upperBound))
        index = state.range.upperBound
      case .failure(let error):
        result = .failure(error)
        break PARSE
      }
    }
    return result
  }.ranged()
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
  lhs: @escaping @autoclosure () -> Parser<C, [T]>,
  rhs: @escaping @autoclosure () -> Parser<C, [T]>
) -> Parser<C, [T]> {
  chain(lhs(), rhs()) >>> { Array($0.joined()) }
}

public func + <C: Collection, T>(
  lhs: @escaping @autoclosure () -> Parser<C, T>,
  rhs: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  chain(lhs(), rhs())
}

public func + <C: Collection, T>(
  lhs: @escaping @autoclosure () -> Parser<C, T>,
  rhs: @escaping @autoclosure () -> Parser<C, [T]>
) -> Parser<C, [T]> {
  lhs().list() + rhs()
}

public func + <C: Collection, T>(
  lhs: @escaping @autoclosure () -> Parser<C, [T]>,
  rhs: @escaping @autoclosure () -> Parser<C, T>
) -> Parser<C, [T]> {
  lhs() + rhs().list()
}
