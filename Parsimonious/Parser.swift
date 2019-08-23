//
//  Parser.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 The type of a Parsimonious parser.
 
 `C` is the `Collection` which parsing consumes. `Context<C>` holds this
 collection, the current _parse index_ (the point in the collection at which
 this parser will attempt to match), and some other state. The parser
 attempts to match a `T`, which is the return type of the parser.
 
 ```
 func foo(_ context: Context<String>) throws -> String {
    return try string("foo")
 }
 ```
 */
public typealias Parser<C: Collection, T> = (Context<C>) throws -> T

public func parse<C: Collection, T>(_ input: C, with parser: Parser<C, T>) throws -> T {
    return try Context(contents: input) <- parser
}

