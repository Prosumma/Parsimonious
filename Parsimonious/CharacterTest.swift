//
//  CharacterTest.swift
//  Parsimonious
//
//  Created by Gregory Higley on 4/11/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public protocol CharacterTest {
    func testCharacter(_ c: Character) -> Bool
}

public func | (lhs: CharacterTest, rhs: CharacterTest) -> CharacterTest {
  test(any: lhs, rhs)
}

public func & (lhs: CharacterTest, rhs: CharacterTest) -> CharacterTest {
  test(all: lhs, rhs)
}

public struct ExplicitCharacterTest: CharacterTest {
    private let _test: (Character) -> Bool
    
    public init(_ test: @escaping (Character) -> Bool) {
        _test = test
    }
    
    public func testCharacter(_ c: Character) -> Bool {
        return _test(c)
    }
}

public func test(all tests: [CharacterTest]) -> CharacterTest {
    return ExplicitCharacterTest { c in
        for test in tests {
            if !test.testCharacter(c) { return false }
        }
        return true
    }
}

public func test(all tests: CharacterTest...) -> CharacterTest {
    return test(all: tests)
}

public func test(any tests: [CharacterTest]) -> CharacterTest {
    return ExplicitCharacterTest { c in
        for test in tests {
            if test.testCharacter(c) { return true }
        }
        return false
    }
}

public func test(any tests: CharacterTest...) -> CharacterTest {
    return test(any: tests)
}

extension Character: CharacterTest {
    public func testCharacter(_ c: Character) -> Bool {
        return c == self
    }
}

extension String: CharacterTest {
    public func testCharacter(_ c: Character) -> Bool {
        return self.contains(c)
    }
}

extension KeyPath: CharacterTest where Root == Character, Value == Bool {
    public func testCharacter(_ c: Character) -> Bool {
        return c[keyPath: self]
    }
}

public prefix func !(test: CharacterTest) -> CharacterTest {
    return ExplicitCharacterTest{ !test.testCharacter($0) }
}

public func ichar(_ character: Character) -> CharacterTest {
    if !character.isLowercase && !character.isUppercase { return character }
    let lowercased = character.lowercased()
    return ExplicitCharacterTest { $0.lowercased() == lowercased }
}

public func istring(_ string: String) -> CharacterTest {
    let lowercased = string.lowercased()
    return ExplicitCharacterTest { lowercased.contains($0.lowercased()) }
}
