# SmartPrinter — iOS/Xcode Project

## Project Type
Native iOS app built with Swift + SwiftUI. **No web dev server.** No `npm`, no `node`, no web build step.

## Verification
Code changes are verified by building with Xcode:
```
xcodebuild -scheme SmartPrinter -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.0' -configuration Debug build
```
A successful build (`** BUILD SUCCEEDED **`) is the correct verification. Do NOT call `preview_start` — there is no web server to start.

## Preview Tools
`preview_*` tools are **not applicable** to this project. The only exception is the bundled PDF Tools web content (`SmartPrinter/PDFTools/www/`) which is pre-built static HTML served from a `launch.json` config — but changes to `app-overrides.css` in that folder do not require a running server to verify; a successful Xcode build is sufficient.

## Stack
- **iOS app**: Swift 5, SwiftUI, UIKit
- **Firebase**: Firestore + Storage for templates/forms
- **Xcode scheme**: `SmartPrinter`
- **Min target**: iOS 16+
