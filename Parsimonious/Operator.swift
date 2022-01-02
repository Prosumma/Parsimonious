//
//  Operators.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2019-03-17.
//  Copyright © 2019 Prosumma LLC.
//
//  Licensed under the MIT license: https://opensource.org/licenses/MIT
//  Permission is granted to use, copy, modify, and redistribute the work.
//  Full license information available in the project LICENSE file.
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
infix operator   <<: CompositionPrecedence

postfix operator *
postfix operator +
