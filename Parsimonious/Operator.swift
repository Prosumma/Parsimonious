//
//  Operators.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/17/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

precedencegroup CompositionPrecedence {
    associativity: right
}

infix operator  <%>: ComparisonPrecedence
infix operator  <=>: ComparisonPrecedence
infix operator   *>: AdditionPrecedence
infix operator   <*: AdditionPrecedence
infix operator   <-: FunctionArrowPrecedence
infix operator  <?>: DefaultPrecedence // TODO: Change this
infix operator  <*>: MultiplicationPrecedence

postfix operator *
postfix operator +
