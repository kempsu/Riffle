# Examples

## RiffleDemo

A small SwiftUI iOS app that uses Riffle via a local package reference (`../..`).
It shows a three-card stack (Pro upsell, Rate prompt, Tip) with live controls for
eligibility, looping, auto-advance, stack depth, and transition.

Open `RiffleDemo/RiffleDemo.xcodeproj` in Xcode and run, or from the command line:

```sh
xcodebuild -project Examples/RiffleDemo/RiffleDemo.xcodeproj \
  -scheme RiffleDemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Requires iOS 17+. Because the package is referenced by relative path, the demo
always builds against the Riffle sources in this repo.
