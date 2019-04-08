//
//  Operators.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/17/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

precedencegroup RunPrecedence {
    associativity: left
    higherThan: AssignmentPrecedence
}

precedencegroup DiscardPrecedence {
    associativity: left
    higherThan: RunPrecedence
    lowerThan: AdditionPrecedence
}

precedencegroup LiftPrecedence {
    associativity: left
    lowerThan: TernaryPrecedence
}

infix operator  <?>: DefaultPrecedence
infix operator  <*>: LiftPrecedence
infix operator   *>: DiscardPrecedence
infix operator   <*: DiscardPrecedence
infix operator   <-: RunPrecedence

postfix operator + // many1
postfix operator ++ // many1S
postfix operator * // many
postfix operator *+ // manyS
postfix operator *? // optional
