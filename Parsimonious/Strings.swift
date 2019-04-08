//
//  Strings.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public struct ExplicitCharacterTest: CharacterTest {
    private let _test: (Character) -> Bool
    
    public init(_ test: @escaping (Character) -> Bool) {
        _test = test
    }
    
    public func test(_ c: Character) -> Bool {
        return _test(c)
    }
}

extension Character: CharacterTest {
    public func test(_ c: Character) -> Bool {
        return c == self
    }
}

public prefix func !(keyPath: KeyPath<Character, Bool>) -> CharacterTest {
    return ExplicitCharacterTest{ c in !c[keyPath: keyPath] }
}

public prefix func !(character: Character) -> CharacterTest {
    return ExplicitCharacterTest{ c in c != character }
}

public func optionalS(_ parser: @escaping Parser<String>, default defaultValue: String = "") -> Parser<String> {
    return { context in
        return (try? parser(context)) ?? defaultValue
    }
}

public func joined<S: StringProtocol>(_ strings: [S]) -> String {
    return strings.joined()
}

public func manyS(_ parser: @escaping Parser<String>) -> Parser<String> {
    return joined <*> parser*
}

public postfix func *+(parser: @escaping Parser<String>) -> Parser<String> {
    return manyS(parser)
}

public func many1S(_ parser: @escaping Parser<String>) -> Parser<String> {
    return joined <*> parser+
}

public postfix func ++(parser: @escaping Parser<String>) -> Parser<String> {
    return many1S(parser)
}

public func countS(_ range: Range<Int>, _ parser: @escaping Parser<String>) -> Parser<String> {
    return joined <*> count(range, parser)
}

public func countS(_ number: Int, _ parser: @escaping Parser<String>) -> Parser<String> {
    return joined <*> count(number, parser)
}

public func join<Parsers: Sequence>(_ parsers: Parsers) -> Parser<String> where Parsers.Element == Parser<String> {
    return joined <*> concat(parsers)
}

public func join(_ parsers: Parser<String>...) -> Parser<String> {
    return join(parsers)
}

public func +(lhs: @escaping Parser<String>, rhs: @escaping Parser<String>) -> Parser<String> {
    return join(lhs, rhs)
}

public protocol CharacterTest {
    func test(_ c: Character) -> Bool
}

extension KeyPath: CharacterTest where Root == Character, Value == Bool {
    public func test(_ c: Character) -> Bool {
        return c[keyPath: self]
    }
}

public func satisfy(_ test: @escaping (Character) -> Bool) -> Parser<String> {
    return { context in
        if let c = context.substring?.first {
            if test(c) {
                context.offset(by: 1)
                return String(c)
            }
            throw ParseError(message: "Unexpected \(c).", context: context)
        }
        throw ParseError(message: "Unexpected end of input.", context: context)
    }
}

public func satisfy<KeyPaths: Sequence>(any keyPaths: KeyPaths) -> Parser<String> where KeyPaths.Element == CharacterTest {
    return satisfy{ c in
        for keyPath in keyPaths {
            if keyPath.test(c) {
                return true
            }
        }
        return false
    }
}

public func satisfy(any keyPaths: CharacterTest...) -> Parser<String> {
    return satisfy(any: keyPaths)
}

public func satisfy<KeyPaths: Sequence>(all keyPaths: KeyPaths) -> Parser<String> where KeyPaths.Element == CharacterTest {
    return satisfy { c in
        for keyPath in keyPaths {
            if !keyPath.test(c) {
                return false
            }
        }
        return true
    }
}

public func satisfy(all keyPaths: CharacterTest...) -> Parser<String> {
    return satisfy(all: keyPaths)
}

public func satisfy(_ keyPath: CharacterTest) -> Parser<String> {
    return satisfy(any: keyPath)
}

public func char(_ c: Character) -> Parser<String> {
    return satisfy(c) <?> "Expected '\(c)'."
}

public func oneOf(_ chars: String) -> Parser<String> {
    return satisfy{ chars.contains($0) }
}

public func noneOf(_ chars: String) -> Parser<String> {
    return satisfy{ !chars.contains($0) }
}

public func match(_ m: String, options: String.CompareOptions = []) -> Parser<String> {
    return { context in
        guard let substring = context.substring else {
            throw ParseError(message: "Unexpected end of input, expected to match \(m).", context: context)
        }
        var options = options
        options.insert(.anchored)
        guard let range = substring.range(of: m, options: options, range: nil, locale: nil) else {
            throw ParseError(message: "Unexpected \(substring.first!), expected to match \(m).", context: context)
        }
        let value = String(substring[range])
        context.offset(by: value)
        return value
    }
}

public func string(_ s: String) -> Parser<String> {
    return match(s)
}

public func caseInsensitiveString(_ s: String) -> Parser<String> {
    return match(s, options: .caseInsensitive)
}

public func regex(_ r: String, options: String.CompareOptions = []) -> Parser<String> {
    var options = options
    options.insert(.regularExpression)
    return match(r, options: options)
}

public let newline = satisfy(\Character.isNewline)
public let whitespace = satisfy(all: \Character.isWhitespace, !\Character.isNewline)
public let whitespaces = many1S(whitespace)

public let whitespaceOrNewline = satisfy(any: \Character.isWhitespace, \Character.isNewline)
public let whitespacesOrNewlines = many1S(whitespaceOrNewline)

public let punctuation = satisfy(\Character.isPunctuation)
public let punctuations = many1S(punctuation)

public let number = satisfy(\Character.isNumber)
public let numbers = many1S(number)

public let digit = oneOf("0123456789")
public let digits = many1S(digit)

public let letter = satisfy(\Character.isLetter)
public let letters = many1S(letter)

public let alpha = regex("[a-z]", options: .caseInsensitive)
public let alphas = regex("[a-z]+", options: .caseInsensitive)

public let alphaNum = regex("[a-z0-9]", options: .caseInsensitive)
public let alphaNums = regex("[a-z0-9]+", options: .caseInsensitive)

public let sofS = {_ in ""} <*> sof
public let eofS: Parser<String> = {_ in ""} <*> eof

public let spaces = (eofS | whitespaces | sofS) <?> "Expected start of input, whitespace, or end of input."

public func string(startDelimiter start: Character, endDelimiter end: Character, escapeCharacter escape: Character = "\\") -> Parser<String> {
    let parseEscaped = char(escape) *> oneOf("\(escape)\(start)\(end)")
    let parseUnescaped = noneOf("\(escape)\(start)\(end)")
    return char(start) *> (parseEscaped | parseUnescaped)*+ <* char(end)
}

public func string(delimitedBy delimiter: Character, escapeCharacter escape: Character = "\\") -> Parser<String> {
    return string(startDelimiter: delimiter, endDelimiter: delimiter, escapeCharacter: escape)
}

