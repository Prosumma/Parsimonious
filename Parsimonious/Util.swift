//
//  Util.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

func not<T>(_ test: @escaping (T) -> Bool) -> (T) -> Bool {
    return { !test($0) }
}

prefix func !<T>(test: @escaping (T) -> Bool) -> (T) -> Bool {
    return not(test)
}

