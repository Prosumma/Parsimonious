//
//  Parser.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public typealias Parser<C: Collection, T> = (Context<C>) throws -> T

public func parse<C: Collection, T>(_ collection: C, with parser: Parser<C, T>) throws -> T {
    return try Context(contents: collection) <- parser
}

