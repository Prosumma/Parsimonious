Parsimonious is a simple, lightweight, and slightly unorthodox parser combinator library for Swift 2.0. It's currently a work in progress, though it's very nearly complete.

Here's a very silly, contrived example:

```swift
let yes = skipNothing <* match <* "yes" & opt <* (matchOneOf <* "!?." | regex <* "\\d")+ *> concat
let no = skip <* match <* "no"
let yesOrNo = yes | no
let grammar = skipWhitespace <* caseInsensitive <* (yesOrNo+ & end)
print(ParseContext.parse("yes!  no yes.no yes23! YES yeS   no", parser: grammar))
```

Since the "no" matches are skipped, this effectively returns the following matches: `["yes!", "yes.", "yes23!", "YES", "yeS"]`. (It actually returns them as tuples of the match and its position in the parsed string.)

Clearly this explanation is not clear. :) Once things are firmed up and the unit tests are written, I will elaborate this README.
