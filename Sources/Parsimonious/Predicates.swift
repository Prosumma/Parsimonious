//
//  Predicates.swift
//  Parsimonious
//
//  Created by Greg Higley on 2023-10-23.
//

import Foundation

public typealias ElementPredicate<T> = @Sendable (T) -> Bool
public typealias KeyPathPredicate<T> = KeyPath<T, Bool>
typealias SendableKeyPathPredicate<T> = KeyPathPredicate<T> & Sendable

public func only<T>(_ keyPath: KeyPathPredicate<T>) -> ElementPredicate<T> {
  let keyPath = unsafeBitCast(keyPath, to: SendableKeyPathPredicate<T>.self)  
  return { $0[keyPath: keyPath] }
}

public func only<T: Equatable & Sendable>(_ model: T) -> ElementPredicate<T> {
  return { $0 == model }
}

public func `any`<T>(_ predicates: [ElementPredicate<T>]) -> ElementPredicate<T> {
  return {
    var result = false
    for predicate in predicates {
      if predicate($0) {
        result = true
        break
      }
    }
    return result
  }
}

public func `any`<T>(_ predicates: ElementPredicate<T>...) -> ElementPredicate<T> {
  any(predicates)
}

public func `any`<T>(_ predicates: [KeyPathPredicate<T>]) -> (T) -> Bool {
  any(predicates.map(only))
}

public func `any`<T>(_ predicates: KeyPathPredicate<T>...) -> (T) -> Bool {
  any(predicates)
}

public func `any`<T: Equatable & Sendable>(_ models: [T]) -> ElementPredicate<T> {
  any(models.map(only))
}

public func `any`<T: Equatable & Sendable>(_ models: T...) -> ElementPredicate<T> {
  any(models)
}

public func all<T>(_ predicates: [ElementPredicate<T>]) -> ElementPredicate<T> {
  return {
    var result = true
    for predicate in predicates {
      if !predicate($0) {
        result = false
        break
      }
    }
    return result
  }
}

public func all<T>(_ predicates: ElementPredicate<T>...) -> ElementPredicate<T> {
  all(predicates)
}

public func not<T>(_ predicate: @escaping ElementPredicate<T>) -> ElementPredicate<T> {
  return { !predicate($0) }
}

public func not<T>(_ keyPath: KeyPathPredicate<T>) -> ElementPredicate<T> {
  return not(only(keyPath))
}

public func not<T: Equatable & Sendable>(_ model: T) -> ElementPredicate<T> {
  { $0 != model }
}

public func || <T>(lhs: @escaping ElementPredicate<T>, rhs: @escaping ElementPredicate<T>) -> ElementPredicate<T> {
  any(lhs, rhs)
}

public func && <T>(lhs: @escaping ElementPredicate<T>, rhs: @escaping ElementPredicate<T>) -> ElementPredicate<T> {
  all(lhs, rhs)
}

public prefix func ^ <T>(keyPath: KeyPathPredicate<T>) -> ElementPredicate<T> {
  only(keyPath)
}

public prefix func ^ <T: Equatable & Sendable>(model: T) -> ElementPredicate<T> {
  only(model)
}

public prefix func ! <T>(predicate: @escaping ElementPredicate<T>) -> ElementPredicate<T> {
  not(predicate)
}

public prefix func ! <T>(keyPath: KeyPathPredicate<T>) -> ElementPredicate<T> {
  not(keyPath)
}

public prefix func ! <T: Equatable & Sendable>(model: T) -> ElementPredicate<T> {
  not(model)
}
