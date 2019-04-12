//
//  Joined.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func joined(_ strings: [String]) -> String {
    return strings.joined()
}

public func joined(by sep: String) -> ([String]) -> String {
    return { strings in strings.joined(separator: sep) }
}

