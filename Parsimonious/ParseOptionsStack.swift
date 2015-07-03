//
//  ParseOptionsStack.swift
//  Parsimonious
//
//  Created by Gregory Higley on 7/3/15.
//  Copyright © 2015 Prosumma LLC. All rights reserved.
//

import Foundation

public struct ParseOptions {
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