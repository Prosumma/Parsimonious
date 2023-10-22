//
//  Defaultable.swift
//  Parsimonious
//
//  Created by Gregory Higley on 2023-10-20.
//

public protocol Defaultable {
  static var defaultValue: Self { get }
}

extension Array: Defaultable {
  public static var defaultValue: Self {
    []
  }
}
