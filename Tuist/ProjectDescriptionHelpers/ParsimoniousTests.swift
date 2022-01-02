import ProjectDescription

public let parsimoniousTests = Target(
  name: "ParsimoniousTests",
  platform: .macOS,
  product: .unitTests,
  bundleId: "com.prosumma.Parsimonious",
  sources: [
    "ParsimoniousTests/**"
  ],
  dependencies: [.target(name: "Parsimonious")]
)
