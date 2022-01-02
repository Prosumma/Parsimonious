//
//  Util.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-04-11.
//  Copyright © 2019 Prosumma LLC.
//
//  Licensed under the MIT license: https://opensource.org/licenses/MIT
//  Permission is granted to use, copy, modify, and redistribute the work.
//  Full license information available in the project LICENSE file.
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
