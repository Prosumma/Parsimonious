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

public func char(_ character: Character) -> ParserS {
    return satisfyChar(character)
}

public func oneOf(_ characters: String) -> ParserS {
    return satisfyChar(characters.contains)
}

public func oneOf(_ characters: [Character]) -> ParserS {
    return oneOf(String(characters))
}

public func oneOf(_ characters: Character...) -> ParserS {
    return oneOf(characters)
}

public func noneOf(_ characters: String) -> ParserS {
    return satisfyChar(!characters.contains)
}

public func noneOf(_ characters: [Character]) -> ParserS {
    return noneOf(String(characters))
}

public func noneOf(_ characters: Character...) -> ParserS {
    return noneOf(characters)
}

public func eofS(_ context: Context<String>) throws -> String {
    return try context <- "" <=> eof
}

public func acceptChar(_ context: Context<String>) throws -> String {
    return try context <- satisfyChar{ _ in true }
}

