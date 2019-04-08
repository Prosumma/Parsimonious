//
//  Position.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/31/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public struct Position<T> {
    let startIndex: String.Index
    let endIndex: String.Index
    let value: T
}

public func position<T>(_ parser: @escaping Parser<T>) -> Parser<Position<T>> {
    return transact { context in
        let startIndex = context.index
        let value = try context <- parser
        let endIndex = context.index
        return Position(startIndex: startIndex, endIndex: endIndex, value: value)
    }
}
