//
//  Position.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-03-31.
//  Copyright © 2019 Prosumma LLC.
//
//  Licensed under the MIT license: https://opensource.org/licenses/MIT
//  Permission is granted to use, copy, modify, and redistribute the work.
//  Full license information available in the project LICENSE file.
//

import Foundation

/**
 
 */
public struct Position<C: Collection, T> {
  public let startIndex: C.Index
  public let endIndex: C.Index
  public let value: T
  public var range: Range<C.Index> {
    startIndex..<endIndex
  }
  public init(value: T, startIndex: C.Index, endIndex: C.Index) {
    self.value = value
    self.startIndex = startIndex
    self.endIndex = endIndex
  }
  public init<O>(value: T, at position: Position<C, O>) {
    self.init(value: value, startIndex: position.startIndex, endIndex: position.endIndex)
  }
}

public func position<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, Position<C, T>> {
  transact { context in
    let startIndex = context.index
    let value = try context <- parser
    let endIndex = context.index
    return Position(value: value, startIndex: startIndex, endIndex: endIndex)
  }
}

public func striposition<Positions: Sequence, C: Collection, T>(
  _ positions: Positions
) -> [T] where Positions.Element == Position<C, T> {
  positions.map { $0.value }
}
