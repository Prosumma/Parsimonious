//
//  ParseOptionsStack.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public struct ParseOptions {
    // Yes, it's an optional optional.
    // Passing nil means that the prior value on the stack should be used.
    // Passing Optional.None means that no characters should be skipped.
    // Passing Optional.Some(characterSet) means that the given characters should be skipped
    let skipCharacters: Optional<NSCharacterSet>?
    let caseInsensitive: Bool?
}

public struct RealizedParseOptions {
    let skipCharacters: NSCharacterSet?
    let caseInsensitive: Bool
}

class ParseOptionsStack {
    
    private var stack = [RealizedParseOptions]()
    
    var current: RealizedParseOptions {
        guard let options = stack.first else {
            return RealizedParseOptions(skipCharacters: nil, caseInsensitive: false)
        }
        return options
    }
    
    func push(options: ParseOptions) {
        var skipCharacters = current.skipCharacters
        if let shouldSkipCharacters = options.skipCharacters {
            switch shouldSkipCharacters {
            case .Some(let characterSet): skipCharacters = characterSet
            case .None: skipCharacters = nil
            }
        }
        let realizedOptions = RealizedParseOptions(skipCharacters: skipCharacters, caseInsensitive: options.caseInsensitive ?? current.caseInsensitive)
        stack.append(realizedOptions)
    }
    
    func pop() {
        stack.removeLast()
    }
    
}