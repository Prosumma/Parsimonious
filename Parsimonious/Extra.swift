//
//  Extra.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-05-09.
//  Copyright © 2019 Prosumma LLC.
//
//  Licensed under the MIT license: https://opensource.org/licenses/MIT
//  Permission is granted to use, copy, modify, and redistribute the work.
//  Full license information available in the project LICENSE file.
//

import Foundation

/**
 A combinator that returns a parser that matches when the content of `parser` is surrounded by
 `surroundings`.
 
 For example, instead of
 
 ```swift
 manyS(\Character.isWhitespace) *>
   many1S(!\Character.isWhitespace) <*
     manyS(\Character.isWhitespace)
 ```
 
 we can say
 
 ```swift
 surround(
   many1S(!\Character.isWhitespace),
   with: manyS(\Character.isWhitespace)
 )
 ```
 */
public func surround<C, T, S>(
  _ parser: @escaping Parser<C, T>, with surroundings: @escaping Parser<C, S>
) -> Parser<C, T> {
  surroundings *> parser <* surroundings
}

/**
 A combinator that returns a parser that matches when the content of `parser` is surrounded by
 `surroundings`.
 
 For example, instead of
 
 ```swift
 manyS(\Character.isWhitespace) *>
   many1S(!\Character.isWhitespace) <*
     manyS(\Character.isWhitespace)
 ```
 
 we can say
 
 ```swift
 surround(
   many1S(!\Character.isWhitespace),
   with: manyS(\Character.isWhitespace)
 )
 ```
 */
public func <*><C, T, S>(
  parser: @escaping Parser<C, T>,
  surroundings: @escaping Parser<C, S>
) -> Parser<C, T> {
  surround(parser, with: surroundings)
}
