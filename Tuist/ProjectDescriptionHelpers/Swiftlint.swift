import ProjectDescription

public extension TargetScript {
  static let swiftlint: TargetScript = .pre(script: .swiftlint, name: "Swiftlint")
}

private extension String {
  static let swiftlint = """
  #!/bin/bash

  if which swiftlint >/dev/null; then
    swiftlint
  else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
  """
}
