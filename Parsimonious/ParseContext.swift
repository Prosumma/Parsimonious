//
//  ParseContext.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public class ParseContext {
    
    // MARK: - Object Lifecycle
    
    public init(string: String) {
        self.string = string
        self.position = string.startIndex
    }
    
    // MARK: - Options
    
    private let optionsStack = ParseOptionsStack()
    
    public func pushOptions(options: ParseOptions) {
        optionsStack.push(options)
        skipCharactersIfNeeded()
    }
    
    public func popOptions() {
        optionsStack.pop()
        skipCharactersIfNeeded()
    }
    
    public var options: RealizedParseOptions {
        return optionsStack.current
    }
    
    // MARK: - Parsing
    
    public let string: String
    
    public var position: String.Index {
        didSet {
            skipCharactersIfNeeded()
        }
    }
    
    private var skippingCharacters = false
    
    private func skipCharactersIfNeeded() {
        guard !skippingCharacters else {
            return
        }
        guard let skipCharacters = options.skipCharacters else {
            return
        }
        skippingCharacters = true
        defer {
            skippingCharacters = false
        }
        var p = position
        while p < string.endIndex && skipCharacters.longCharacterIsMember(string[p...p].unicodeScalars.first!.value) {
            p = Swift.advance(p, 1, string.endIndex)
        }
        position = p
    }
    
    public var remainder: String {
        return string[position..<string.endIndex]
    }
    
    public class func parse<T>(string: String, parser: ParseContext -> ParseResult<T>) -> ParseResult<T> {
        return parser(ParseContext(string: string))
    }
}