//
//  OperatorDeclarations.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-19.
//

import Foundation

postfix operator *
postfix operator +
prefix operator *

precedencegroup ApplicativePrecedence {
  associativity: left
  higherThan: LogicalConjunctionPrecedence
  lowerThan: ComparisonPrecedence
}

precedencegroup AlternativePrecedence {
  associativity: left
  higherThan: ApplicativePrecedence
  lowerThan: ComparisonPrecedence
}

precedencegroup FunctorPrecedence {
  associativity: left
  higherThan: AlternativePrecedence
  lowerThan: ComparisonPrecedence
}

infix operator >>=: ApplicativePrecedence
infix operator *>=: ApplicativePrecedence
infix operator <* : ApplicativePrecedence
infix operator  *>: ApplicativePrecedence
infix operator <|>: AlternativePrecedence

infix operator >>>: FunctorPrecedence
infix operator *>>: FunctorPrecedence
