//
//  Strings.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func +(lparser: @escaping ParserS, rparser: @escaping ParserS) -> ParserS {
    return transact { context in try lparser(context) + rparser(context) }
}

public func eofS(_ context: Context<String>) throws -> String {
    return try context <- "" <=> eof
}

public func acceptChar(_ context: Context<String>) throws -> String {
    return try context <- char{ _ in true }
}

