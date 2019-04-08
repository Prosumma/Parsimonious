//
//  Parser.swift
//  Parsimonious
//
//  Created by Gregory Higley on 3/19/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public typealias Parser<C: Collection, T> = (Context<C>) throws -> T
