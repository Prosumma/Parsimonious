//
//  Context.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-02-28.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 The `Context` type holds the collection over which parsing
 occurs as well as the index into that collection at which parsing
 begins. As parsing proceeds, the index is moved forward.
 */
public class Context<Contents: Collection>: Collection {
  public typealias Element = Contents.Element
  public typealias Index = Contents.Index
  
  public let contents: Contents
  public var index: Index
  private var savedIndices: [Index] = []
  private var state: [String: Any] = [:]

  init(contents: Contents) {
    self.contents = contents
    self.index = self.contents.startIndex
  }
  
  public var startIndex: Index {
    contents.startIndex
  }
  
  public var endIndex: Index {
    contents.endIndex
  }
  
  public subscript(position: Index) -> Element {
    contents[position]
  }
  
  public subscript(_ key: String) -> Any? {
    get { state[key] }
    set { state[key] = newValue }
  }
  
  public func index(after i: Index) -> Index {
    contents.index(after: i)
  }
  
  public var rest: Contents.SubSequence? {
    if atEnd {
      return nil
    }
    return contents[index...]
  }
  
  public var next: Element? {
    rest?.first
  }
  
  public func advance() -> Element? {
    guard let next = self.next else {
      return nil
    }
    defer { offset(by: 1) }
    return next
  }
  
  public var atStart: Bool {
    index == startIndex
  }
  
  public var atEnd: Bool {
    index == endIndex
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
   a `ParseError`, the value of `index` is restored to its value
   before the passed-in function was executed. Otherwise the
   value of `index` is affirmed.
   
   - warning: Any other sort of `Error` will _not_ cause the index
   to be restored.
   
   - parameter fn: The function to execute within the transaction.
   */
  public func transact<T>(_ fn: () throws -> T) throws -> T {
    saveIndex()
    do {
      let result = try fn()
      commitIndex()
      return result
    } catch let error as ParsingError {
      restoreIndex()
      throw error
    }
  }
}

/**
 A convenience function for writing parsers that automatically backtrack.
 
 This is typically used in combinators which take other parsers as input and
 return a parser as output, e.g.,
 
 ```
 func awesome<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, T> {
     return transact { context in
        return try context <- parser
     }
 }
 ```
 */
public func transact<C: Collection, T>(_ parser: @escaping Parser<C, T>) -> Parser<C, T> {
  return { context in try context.transact{ try parser(context) } }
}

/**
 Executes a parser in the given context.
 
 This is useful syntactic sugar when writing custom parsers and combinators. A parser is a
 function which takes a `Context<C: Collection>` as input. One can "run" the parser simply
 by calling it with a `Context<C>` as its only parameter, e.g., `try parser(context)`. However, when
 the parser is _ad hoc_, this is often inconvenient. The `<-` operator makes it easier:
 
 ```
 func foo(_ context: Context<String>) throws -> String {
    return try context.transact {
        return try context <- many1S("aeiou") | many1S("bcdfg")
    }
 }
 ```
 
 The 3rd line of the extremely contrived example above could have been written `return try (many1S("aeiou") | many1S("bcdfg"))(context)` but this leads to an ugly surfeit of parentheses.
 */
@discardableResult
public func <-<C: Collection, T>(_ context: Context<C>, _ parser: Parser<C, T>) throws -> T {
  try parser(context)
}

public extension ParseError {
  init(_ context: Context<Contents>, message: String? = nil, inner: Error? = nil) {
    self.init(context.index, message: message, inner: inner)
  }
}

extension Collection {
  public subscript(upTo limit: Int) -> SubSequence {
    let limitedIndex = index(startIndex, offsetBy: limit, limitedBy: endIndex) ?? endIndex
    return self[startIndex..<limitedIndex]
  }
}
