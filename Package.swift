// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Parsimonious",
  platforms: [.macOS(.v13)],
  products: [
    .library(
      name: "Parsimonious",
      targets: ["Parsimonious"]
    ),
  ],
  targets: [
    .target(name: "Parsimonious"),
    .testTarget(
        name: "ParsimoniousTests",
        dependencies: ["Parsimonious"],
    ),
  ]
)
