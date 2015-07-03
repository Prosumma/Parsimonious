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
    
    public init(stream: ParseStream) {
        self.stream = stream
    }
    
    // MARK: - Options
    
    private let optionsStack = ParseOptionsStack()
    
    public func pushOptions(options: ParseOptions) {
        optionsStack.push(options)
        guard let skipCharacters = self.options.skipCharacters else {
            return
        }
        stream.skipCharacters(skipCharacters)
    }
    
    public func popOptions() {
        optionsStack.pop()
        guard let skipCharacters = options.skipCharacters else {
            return
        }
        stream.skipCharacters(skipCharacters)
    }
    
    public var options: RealizedParseOptions {
        return optionsStack.current
    }
    
    // MARK: - ParseStream
    
    public let stream: ParseStream
    
    

}