//
//  Strings.swift
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

/**
 Executes a sequence of string parsers (i.e., `ParserS`) and
 concatenates the result into a single string. If any one of
 the underlying parsers fails, `concat` fails.
 */
public func concat<Parsers: Sequence>(_ parsers: Parsers) -> ParserS where Parsers.Element == ParserS {
  return transact { context in
    var s = ""
    for parser in parsers {
      s += try context <- parser
    }
    return s
  }
}

/**
 Executes a sequence of string parsers (i.e., `ParserS`) and
 concatenates the result into a single string. If any one of
 the underlying parsers fails, `concat` fails.
 */
public func concat(_ parsers: ParserS...) -> ParserS {
  concat(parsers)
}

/**
 Creates a `ParserS` which concatenates the results of the left- and right-hand
 sides of the operator.
 
 ```
 let identifier = char(\Character.isLetter) + manyS(any: \Character.isLetter, \Character.isNumber)
 ```
 
 The above parser matches a letter followed by zero or more letters or numbers.
 */
public func + (lparser: @escaping ParserS, rparser: @escaping ParserS) -> ParserS {
  concat(lparser, rparser)
}

/**
 Matches EOF.
 
 The difference between this and plain `eof` is that `eofS` is useful in
 contexts where the type system demands a `ParserS`, e.g.,
 
 ```
 let ws = manyS(\Character.isWhitespace)
 let identifier = char(\Character.isLetter)
                  + manyS(any: \Character.isLetter, \Character.isNumber)
 let parser = identifier <* (ws | char(")") | eofS)
 ```
 
 This `parser` would be much harder to write without `eofS`.
 */
public func eofS(_ context: Context<String>) throws -> String {
  try context <- "" <=> eof
}

/**
 Matches any character.
 
 Chiefly useful for matching a specific number of characters, e.g.,
 `countS(7, acceptChar)` matches any seven characters.
 
 Does not match EOF.
 */
public func acceptChar(_ context: Context<String>) throws -> String {
  try context <- char { _ in true }
}

public func quote(_ delimiter: Character, _ escape: Character = "\\") -> ParserS {
  assert(delimiter != escape, "The quote combinator does not support using the same delimiter and escape character.")
  return manyS(char(all: !escape, !delimiter) | (char(escape) *> char(any: escape, delimiter))) <*> char(delimiter)
}

/**
 A typical quoted string with `"` and backslashes escaped by a backslash.
 
 - warning: The escape character `\\` is used *only* to escape itself and
 the quote character. It does not handle escaping of the sort used in programming
 languages such as C. (This would not make sense, since different languages
 escape things differently.) If you want to parse a C-style string, you
 will have to roll your own parser, which is not very difficult algorithmically.
 */
public func quotation(_ context: Context<String>) throws -> String {
  try context <- quote("\"")
}
