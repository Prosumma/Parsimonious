//
//  OperatorDeclarations.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2026-10-05.
//

postfix operator *
postfix operator +

precedencegroup AlternativePrecedence {
  associativity: left
  higherThan: LogicalConjunctionPrecedence
  lowerThan: ComparisonPrecedence
}

precedencegroup ApplicativePrecedence {
  associativity: left
  higherThan: AlternativePrecedence
  lowerThan: ComparisonPrecedence
}

infix operator <* : ApplicativePrecedence
infix operator  *>: ApplicativePrecedence
infix operator <|>: AlternativePrecedence
