//
//  Position.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/31/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public struct Position<C: Collection, T> {
    public let startIndex: C.Index
    public let endIndex: C.Index
    public let value: T
    public var range: Range<C.Index> {
        return startIndex..<endIndex
    }
}

public func position<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, Position<C, T>> {
    return transact { context in
        let startIndex = context.index
        let value = try context <- parser
        let endIndex = context.index
        return Position(startIndex: startIndex, endIndex: endIndex, value: value)
    }
}