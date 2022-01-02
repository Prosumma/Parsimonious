import ProjectDescription

public let parsimonious = Target(
  name: "Parsimonious",
  platform: .macOS,
  product: .framework,
  bundleId: "com.prosumma.Parsimonious",
  sources: [
    "Parsimonious/**"
  ],
  scripts: [.swiftlint]
)
