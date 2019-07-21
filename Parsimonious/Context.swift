//
//  Context.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2/28/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public class Context<Contents: Collection> {
    public let contents: Contents
    public var index: Contents.Index
    private var savedIndices: [Contents.Index] = []
    private var state: [String: Any] = [:]

    init(contents: Contents) {
        self.contents = contents
        self.index = self.contents.startIndex
    }
    
    public subscript(_ key: String) -> Any? {
        get { return state[key] }
        set { state[key] = newValue }
    }
    
    public var rest: Contents.SubSequence? {
        if index == contents.endIndex {
            return nil
        }
        return contents[index...]
    }
    
    public var next: Contents.Element? {
        return rest?.first
    }
    
    public var atStart: Bool {
        return index == contents.startIndex
    }
    
    public var atEnd: Bool {
        return index == contents.endIndex
    }
    
    public func offset(by offset: Int) {
        self.index = contents.index(self.index, offsetBy: offset, limitedBy: self.contents.endIndex) ?? self.contents.endIndex
    }

    public func offset(by contents: Contents) {
        offset(by: contents.count)
    }
    
    public func offset(by contents: Contents.SubSequence) {
        offset(by: contents.count)
    }
    
    public func saveIndex() {
        savedIndices.append(index)
    }
    
    public func commitIndex() {
        savedIndices.removeLast()
    }
    
    public func restoreIndex() {
        self.index = savedIndices.removeLast()
    }
    
    /**
     Starts a transaction against the context's `index`.
     
     The function passed to `transact` is executed. If it throws
     an exception, the value of `index` is restored to its value
     before the passed-in function was executed. Otherwise the
     value of `index` is affirmed.
     
     - parameter fn: The function to execute within the transaction.
     */
    public func transact<T>(_ fn: () throws -> T) throws -> T {
        saveIndex()
        do {
            let result = try fn()
            commitIndex()
            return result
        } catch let error as ParseError<Contents> {
            restoreIndex()
            throw error
        }
    }
}

public func transact<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, T> {
    return { context in try context.transact{ try parser(context) } }
}

@discardableResult
public func <-<C: Collection, T>(_ context: Context<C>, _ parser: Parser<C, T>) throws -> T {
    return try parser(context)
}

public extension ParseError {
    init(message: String, context: Context<Contents>, inner: Error? = nil) {
        self.init(message: message, contents: context.contents, index: context.index, inner: inner)
    }
}

extension Collection {
    public subscript(upTo limit: Int) -> SubSequence {
        let limitedIndex = index(startIndex, offsetBy: limit, limitedBy: endIndex) ?? endIndex
        return self[startIndex..<limitedIndex]
    }
}
