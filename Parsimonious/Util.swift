//
//  Util.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

infix operator <<: CompositionPrecedence

public func not<T>(_ test: @escaping (T) -> Bool) -> (T) -> Bool {
    return { !test($0) }
}

public prefix func !<T>(test: @escaping (T) -> Bool) -> (T) -> Bool {
    return not(test)
}

/**
 Simple function composition.
 */
func <<<A, B, C>(lhs: @escaping (B) -> C, rhs: @escaping (A) -> B) -> (A) -> C {
    return { lhs(rhs($0)) }
}
