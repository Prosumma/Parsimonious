//
//  Context.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2/28/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public class Context {
    fileprivate let string: String
    public private(set) var index: String.Index
    private var savedIndices: [String.Index] = []
    
    init<S: StringProtocol>(string: S) {
        self.string = String(string)
        self.index = self.string.startIndex
    }
    
    public var substring: Substring? {
        if index == string.endIndex {
            return nil
        }
        return string[index...]
    }
    
    public var atStart: Bool {
        return index == string.startIndex
    }
    
    public var atEnd: Bool {
        return index == string.endIndex
    }
    
    public func offset(by offset: Int) {
        self.index = string.index(self.index, offsetBy: offset, limitedBy: self.string.endIndex) ?? self.string.endIndex
    }

    public func offset<S: StringProtocol>(by string: S) {
        offset(by: string.count)
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
        } catch {
            restoreIndex()
            throw error
        }
    }
}

public func transact<T>(_ parser: @escaping Parser<T>) -> Parser<T> {
    return { context in try context.transact{ try parser(context) } }
}

@discardableResult
public func <-<T>(_ context: Context, _ parser: Parser<T>) throws -> T {
    return try parser(context)
}

public extension ParseError {
    init(message: String, context: Context) {
        self.init(message: message, string: context.string, index: context.index)
    }
}

public struct Debug: OptionSet, ExpressibleByIntegerLiteral {
    public var rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public init(integerLiteral value: UInt) {
        self.init(rawValue: value)
    }
    
    public static let none: Debug = 0
    public static let before: Debug = 1
    public static let after: Debug = 2
    public static let error: Debug = 4
    public static let all: Debug = [.before, .after, .error]
}

public typealias DebugLogger = (String) -> Void

func debugFormat(_ context: Context, error: Error? = nil) -> String {
    let startIndex = context.string.startIndex
    let offset = context.string.distance(from: startIndex, to: context.index)
    if let error = error {
        if let substring = context.substring {
            return "OFFSET \(offset) ERROR \"\(error)\" SUBSTRING \"\(substring)\""
        }
        return "OFFSET \(offset) ERROR \"\(error)\" EOF"
    } else {
        if let substring = context.substring {
            return "OFFSET \(offset) SUBSTRING \"\(substring)\""
        }
        return "OFFSET \(offset) EOF"
    }
}

/*
public func debug<T>(_ parser: @escaping Parser<T>, _ debug: Debug = .all, _ log: DebugLogger? = nil) -> Parser<T> {
    let log: DebugLogger = log ?? { s in print(s) }
    return withParseContext { context in
        if (debug.contains(.before)) {
            log(debugFormat(context))
        }
        defer {
            if (debug.contains(.after)) {
                log(debugFormat(context))
            }
        }
        do {
            return try context.parse(with: parser)
        } catch {
            if (debug.contains(.error)) {
                log(debugFormat(context, error: error))
            }
            throw error
        }
    }
}
*/
