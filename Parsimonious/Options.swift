//
//  Options.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public func withOptions<T>(parser: ParseContext -> ParseResult<T>, options: ParseOptions)(_ context: ParseContext) -> ParseResult<T> {
    context.pushOptions(options)
    defer {
        context.popOptions()
    }
    return parser(context)
}