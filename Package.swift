// swift-tools-version:5.0
//
//  Package.swift
//  Parsimonious
//
//  Created by Gregory Higley on 6/8/19.
//  Copyright © 2019 Gregory Higley. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "Parsimonious",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "Parsimonious",
            targets: ["Parsimonious"])
    ],
    targets: [
        .target(
            name: "Parsimonious",
            path: "Parsimonious")
    ],
    swiftLanguageVersions: [.v5]
)
