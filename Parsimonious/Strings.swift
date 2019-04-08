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

public func optionalS(_ parser: @escaping Parser<String, String>, default defaultValue: String = "") -> Parser<String, String> {
    return { context in
        return (try? parser(context)) ?? defaultValue
    }
}

public func joined<S: StringProtocol>(_ strings: [S]) -> String {
    return strings.joined()
}

public func manyS(_ parser: @escaping Parser<String, String>) -> Parser<String, String> {
    return joined <*> parser*
}

public postfix func *+(parser: @escaping Parser<String, String>) -> Parser<String, String> {
    return manyS(parser)
}

public func many1S(_ parser: @escaping Parser<String, String>) -> Parser<String, String> {
    return joined <*> parser+
}

public postfix func ++(parser: @escaping Parser<String, String>) -> Parser<String, String> {
    return many1S(parser)
}

public func countS(_ range: Range<Int>, _ parser: @escaping Parser<String, String>) -> Parser<String, String> {
    return joined <*> count(range, parser)
}

public func countS(_ number: Int, _ parser: @escaping Parser<String, String>) -> Parser<String, String> {
    return joined <*> count(number, parser)
}

public func join<Parsers: Sequence>(_ parsers: Parsers) -> Parser<String, String> where Parsers.Element == Parser<String, String> {
    return joined <*> concat(parsers)
}

public func join(_ parsers: Parser<String, String>...) -> Parser<String, String> {
    return join(parsers)
}

public func +(lhs: @escaping Parser<String, String>, rhs: @escaping Parser<String, String>) -> Parser<String, String> {
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

public func satisfyS(_ test: @escaping (Character) -> Bool) -> Parser<String, String> {
    return { c in String(c) } <*> satisfy(test)
}

public func satisfyS<KeyPaths: Sequence>(any keyPaths: KeyPaths) -> Parser<String, String> where KeyPaths.Element == CharacterTest {
    return satisfyS{ c in
        for keyPath in keyPaths {
            if keyPath.test(c) {
                return true
            }
        }
        return false
    }
}

public func satisfyS(any keyPaths: CharacterTest...) -> Parser<String, String> {
    return satisfyS(any: keyPaths)
}

public func satisfyS<KeyPaths: Sequence>(all keyPaths: KeyPaths) -> Parser<String, String> where KeyPaths.Element == CharacterTest {
    return satisfyS { c in
        for keyPath in keyPaths {
            if !keyPath.test(c) {
                return false
            }
        }
        return true
    }
}

public func satisfyS(all keyPaths: CharacterTest...) -> Parser<String, String> {
    return satisfyS(all: keyPaths)
}

public func satisfyS(_ keyPath: CharacterTest) -> Parser<String, String> {
    return satisfyS(any: keyPath)
}

public func char(_ c: Character) -> Parser<String, String> {
    return satisfyS(c) <?> "Expected '\(c)'."
}

public func oneOf(_ chars: String) -> Parser<String, String> {
    return satisfyS{ chars.contains($0) }
}

public func noneOf(_ chars: String) -> Parser<String, String> {
    return satisfyS{ !chars.contains($0) }
}

public func match(_ m: String, options: String.CompareOptions = []) -> Parser<String, String> {
    return { context in
        guard let substring = context.subcontents else {
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

public func string(_ s: String) -> Parser<String, String> {
    return match(s)
}

public func caseInsensitiveString(_ s: String) -> Parser<String, String> {
    return match(s, options: .caseInsensitive)
}

public func regex(_ r: String, options: String.CompareOptions = []) -> Parser<String, String> {
    var options = options
    options.insert(.regularExpression)
    return match(r, options: options)
}

public let newline = satisfyS(\Character.isNewline)
public let whitespace = satisfyS(all: \Character.isWhitespace, !\Character.isNewline)
public let whitespaces = many1S(whitespace)

public let whitespaceOrNewline = satisfyS(any: \Character.isWhitespace, \Character.isNewline)
public let whitespacesOrNewlines = many1S(whitespaceOrNewline)

public let punctuation = satisfyS(\Character.isPunctuation)
public let punctuations = many1S(punctuation)

public let number = satisfyS(\Character.isNumber)
public let numbers = many1S(number)

public let digit = oneOf("0123456789")
public let digits = many1S(digit)

public let letter = satisfyS(\Character.isLetter)
public let letters = many1S(letter)

public let alpha = regex("[a-z]", options: .caseInsensitive)
public let alphas = regex("[a-z]+", options: .caseInsensitive)

public let alphaNum = regex("[a-z0-9]", options: .caseInsensitive)
public let alphaNums = regex("[a-z0-9]+", options: .caseInsensitive)

public let sofS: Parser<String, String> = {_ in ""} <*> sof
public let eofS: Parser<String, String> = {_ in ""} <*> eof

public let spaces = (eofS | whitespaces | sofS) <?> "Expected start of input, whitespace, or end of input."

public func string(startDelimiter start: Character, endDelimiter end: Character, escapeCharacter escape: Character = "\\") -> Parser<String, String> {
    let parseEscaped = char(escape) *> oneOf("\(escape)\(start)\(end)")
    let parseUnescaped = noneOf("\(escape)\(start)\(end)")
    return char(start) *> (parseEscaped | parseUnescaped)*+ <* char(end)
}

public func string(delimitedBy delimiter: Character, escapeCharacter escape: Character = "\\") -> Parser<String, String> {
    return string(startDelimiter: delimiter, endDelimiter: delimiter, escapeCharacter: escape)
}

