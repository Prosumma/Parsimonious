//
//  File.swift
//  
//
//  Created by Greg Higley on 2023-10-19.
//

import Foundation

postfix operator *
postfix operator +

precedencegroup ApplicativePrecedence {
  associativity: left
  higherThan: LogicalConjunctionPrecedence
}

precedencegroup AlternativePrecedence {
  associativity: left
  higherThan: ApplicativePrecedence
}

precedencegroup FunctorPrecedence {
  associativity: left
  higherThan: AlternativePrecedence
  lowerThan: ComparisonPrecedence
}

infix operator >>=: ApplicativePrecedence
infix operator *>=: ApplicativePrecedence
infix operator  <*: ApplicativePrecedence
infix operator  *>: ApplicativePrecedence
infix operator <|>: AlternativePrecedence

infix operator >>>: FunctorPrecedence
infix operator *>>: FunctorPrecedence
