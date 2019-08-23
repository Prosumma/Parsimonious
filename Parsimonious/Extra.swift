//
//  Extra.swift
//  Parsimonious
//
//  Created by Gregory Higley on 5/9/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 A combinator that returns a parser that matches when the content of `parser` is surrounded by
 `surroundings`.
 
 For example, instead of `manyS(\Character.isWhitespace) *> many1S(!\Character.isWhitespace) <* manyS(\Character.isWhitespace)` we can say `surround(many1S(!\Character.isWhitespace), manyS(\Character.isWhitespace)`.
 */
public func surround<C, T, S>(_ parser: @escaping Parser<C, T>, with surroundings: @escaping Parser<C, S>) -> Parser<C, T> {
    return surroundings *> parser <* surroundings
}

public func <*><C, T, S>(parser: @escaping Parser<C, T>, surroundings: @escaping Parser<C, S>) -> Parser<C, T> {
    return surround(parser, with: surroundings)
}
