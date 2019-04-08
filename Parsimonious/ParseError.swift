//
//  ParseError.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public struct ParseError: Error {
    public let message: String
    public let string: String
    public let index: String.Index
    
    public init(message: String, string: String, index: String.Index) {
        self.message = message
        self.string = string
        self.index = index
    }
}
