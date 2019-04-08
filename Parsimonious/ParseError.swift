//
//  ParseError.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public struct ParseError<Contents: Collection>: Error {
    public let message: String
    public let contents: Contents
    public let index: Contents.Index
    
    public init(message: String, contents: Contents, index: Contents.Index) {
        self.message = message
        self.contents = contents
        self.index = index
    }
}
