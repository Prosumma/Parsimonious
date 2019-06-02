//
//  Joined.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/12/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func joined<T>(_ arrays: [[T]]) -> [T] {
    return Array(arrays.joined())
}

public func arrayed<T>(_ value: T) -> [T] {
    return [value]
}
