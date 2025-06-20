// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Parsimonious",
  products: [
    .library(
      name: "Parsimonious",
      targets: ["Parsimonious"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/Prosumma/Iatheto", from: "3.1.0")
  ],
  targets: [
    .target(name: "Parsimonious"),
    .testTarget(
        name: "ParsimoniousTests",
        dependencies: ["Parsimonious", "Iatheto"],
        resources: [
          .copy("JSON.json")
        ]
    ),
  ]
)
