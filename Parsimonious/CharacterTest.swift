//
//  CharacterTest.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public protocol CharacterTest {
    func test(_ c: Character) -> Bool
}

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

extension KeyPath: CharacterTest where Root == Character, Value == Bool {
    public func test(_ c: Character) -> Bool {
        return c[keyPath: self]
    }
}

public prefix func !(character: Character) -> CharacterTest {
    return ExplicitCharacterTest{ $0 != character }
}

public prefix func !(keyPath: KeyPath<Character, Bool>) -> CharacterTest {
    return ExplicitCharacterTest{ !$0[keyPath: keyPath] }
}
