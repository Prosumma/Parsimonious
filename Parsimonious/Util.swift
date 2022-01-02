//
//  Util.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-04-11.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func not<T>(_ test: @escaping (T) -> Bool) -> (T) -> Bool {
  return { !test($0) }
}

public prefix func ! <T>(test: @escaping (T) -> Bool) -> (T) -> Bool {
  not(test)
}

/// Simple function composition. Works identically to Haskell's . operator.
func <<<A, B, C>(lhs: @escaping (B) -> C, rhs: @escaping (A) -> B) -> (A) -> C {
  return { lhs(rhs($0)) }
}
