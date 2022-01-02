//
//  JoinedS.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-04-11.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func joined(_ strings: [String]) -> String {
  strings.joined()
}

public func joined(by sep: String) -> ([String]) -> String {
  return { strings in strings.joined(separator: sep) }
}

