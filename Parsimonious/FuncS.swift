//
//  JoinedS.swift
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

public func joined(_ strings: [String]) -> String {
  strings.joined()
}

public func joined(by sep: String) -> ([String]) -> String {
  return { strings in strings.joined(separator: sep) }
}
