//
//  Strings.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
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
    return concat(parsers)
}

/**
 Creates a `ParserS` which concatenates the results of the left- and right-hand
 sides of the operator.
 
 ```
 let identifier = char(\Character.isLetter) + manyS(any: \Character.isLetter, \Character.isNumber)
 ```
 
 The above parser matches a letter followed by zero or more letters or numbers.
 */
public func +(lparser: @escaping ParserS, rparser: @escaping ParserS) -> ParserS {
    return concat(lparser, rparser)
}

/**
 Matches EOF.
 
 The difference between this and plain `eof` is that `eofS` is useful in
 contexts where one needs a `ParserS`, e.g.,
 
 ```
 let ws = manyS(\Character.isWhitespace)
 let identifier = char(\Character.isLetter)
                  + manyS(any: \Character.isLetter, \Character.isNumber)
 let parser = identifier <* (ws | char(")") | eofS)
 ```
 
 This `parser` would be much harder to write without `eofS`.
 */
public func eofS(_ context: Context<String>) throws -> String {
    return try context <- "" <=> eof
}

/**
 Matches any character.
 
 Chiefly useful for matching a specific number of characters, e.g.,
 `countS(7, acceptChar)` matches any seven characters.
 */
public func acceptChar(_ context: Context<String>) throws -> String {
    return try context <- char{ _ in true }
}

public func quote(_ delimiter: Character, _ escape: Character = "\\") -> ParserS {
    return surround(manyS(char(all: !escape, !delimiter) | (char(escape) *> char(any: escape, delimiter))), with: char(delimiter))
}

/**
 A typical quoted string with `"` and backslashes escaped by a backslash.
 */
public func quotation(_ context: Context<String>) throws -> String {
    return try context <- quote("\"")
}

