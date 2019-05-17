//
//  Extra.swift
//  Parsimonious
//
//  Created by Gregory Higley on 5/9/19.
//  Copyright © 2019 Prosumma LLC. All rights reserved.
//

import Foundation

public func surround<C, T, S>(_ parser: @escaping Parser<C, T>, with: @escaping Parser<C, S>) -> Parser<C, T> {
    return with *> parser <* with
}

