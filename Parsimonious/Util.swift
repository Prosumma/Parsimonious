//
//  Util.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func not<T>(_ test: @escaping (T) -> Bool) -> (T) -> Bool {
  { !test($0) }
}

public prefix func ! <T>(test: @escaping (T) -> Bool) -> (T) -> Bool {
  not(test)
}

/// Simple function composition. Works identically to Haskell's . operator.
func <<<A, B, C>(lhs: @escaping (B) -> C, rhs: @escaping (A) -> B) -> (A) -> C {
  { lhs(rhs($0)) }
}

