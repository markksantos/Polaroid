# Polaroid (store name TBD) — Mac App Store checklist

Status on 2026-09-22 (branch `appstore-kit`). Nothing has been submitted, signed or uploaded.
This kit lives in the existing `AppStore/` folder, not a new `appstore/`. This Mac's disk is case-insensitive, so `appstore/` and `AppStore/` are the same folder, and adding both casings to git would split the folder in two on case-sensitive checkouts. For the same reason, the old `metadata.md` was renamed with `git mv` to `METADATA.md` and rewritten; the old text is still in git history.

## Ready

- [x] **Metadata**: `METADATA.md` has all fields within Apple's limits (the generator script fails on any overage). It uses the proposed name `Instant Frame`.
- [x] **Screenshot**: `Screenshots/mac-2880x1800/01-drop-an-image.png` is 2880×1800 with no alpha. It's a real window capture from a fresh unsigned Release build. **It has to be retaken after the rename**, because the window's title bar reads "Polaroid".
- [x] **Icon set**: all 10 macOS slots are filled and the **1024×1024** image is present. The build compiles them into `AppIcon.icns` and `Assets.car`.
- [x] **Sandbox**: on (user-selected read-write, app-scope bookmarks, Pictures read-write, and no network). A probe with these exact entitlements confirmed that the default save folder `~/Pictures/Polaroids` is reachable and HTTPS is blocked.
- [x] **Privacy manifest**: present and inside the built bundle. The reason code needs a fix; see below.
- [x] **Build**: the Release build is clean and a **universal binary** (x86_64 + arm64). It launched hidden, rendered its window and quit with no crash report.
- [x] **Support and privacy URLs**: both are live (general NoSleepLab pages).

## Blocks submission, in order

1. **🔴 Rename the app. "Polaroid" is a registered trademark** (Polaroid B.V.; Guideline 5.2.1). The listing copy is already clean, but **the binary still says Polaroid**, and App Review sees the binary: `PRODUCT_NAME: Polaroid` in `project.yml`, the window title, the menu bar extra title, about 30 UI strings ("New Polaroid…", "Recent Polaroids", "Quit Polaroid", "There is no Polaroid to export."), the default save folder `~/Pictures/Polaroids`, and the default file name `Polaroid yyyy-MM-dd HH.mm.ss`. This is a code change for whoever owns the code; nothing here touched app source. Then retake the screenshot.
2. **🔴 Desktop watcher fails in the sandbox without telling anyone.** `autoWatchDesktop` defaults to **on** and watches `NSHomeDirectory()/Desktop`. Under the sandbox that's the container's Desktop symlink, and a probe with the app's entitlements was **denied** (errno 1). On a fresh install the watcher does nothing, and **Rescan Desktop** (in the menu bar item, the toolbar menu and Settings) shows "Desktop scan failed". A reviewer who tries the feature the old README leads with will see it fail (Guideline 2.1). There's also a second bug: `updateWatcher()` resolves the saved folder bookmark but never calls `startAccessingSecurityScopedResource()`, so a folder the user picked should stop being watched after the next relaunch (found by reading the code, not run). Fix: on first run, ask for the screenshots folder with an open panel and start security-scoped access before watching. Or default the watcher to off and hide Rescan until a folder is chosen. The listing copy already leaves this feature out.
3. **Apple Distribution certificate.** This Mac has only `Apple Development: Mark Santos`. Create an **Apple Distribution** cert and a **Mac Installer Distribution** cert (Xcode → Settings → Accounts; needs Mark's Apple ID).
4. **Signing team.** `DEVELOPMENT_TEAM` isn't set in `project.yml`. Set it with automatic signing, then run `xcodegen generate` (the `.xcodeproj` and `Info.plist` are generated).
5. **Register the bundle ID** `com.nosleeplab.Polaroid`. It never appears in the store, so it can stay. Automatic signing registers it.
6. **App Store Connect app record** under the new name, with bundle ID and SKU.
7. **Archive and upload** with the installed release **Xcode 27.0**.
8. **Fill in App Store Connect** from METADATA.md: price (README suggests USD 9), age rating (every answer None/No, giving 4+), App Privacy "Data Not Collected", export compliance "No", and the screenshots.

## Should fix before review (not upload blockers)

- **Don't upload the old `Screenshots/01…06-polaroid.png`.** `generate_screenshots.swift` *draws* them: a fake light-theme window, a fake photo, fake panels. The real app is a dark window with a different toolbar. They also show the word "Polaroid" and advertise the Desktop auto-watch. Store screenshots have to show the real app (Guideline 2.3.3). They're left in place because the README embeds `01-polaroid.png`.
- **The icon is a white square with a clipped shape.** Every PNG in `AppIcon.appiconset` is fully opaque with white corners (bounding box 0,0 to 1024,1024), and the maroon back shape runs off the right and bottom edges. It will show as a white tile with cut-off art. Re-export it with a proper shape and transparent margin. This kit doesn't change icons.
- **Privacy manifest reason code.** The file-timestamp reason `C617.1` only covers files inside the app container. The app reads the `creationDate` of images the user picked (`3B52.1`) and shows it as the date stamp (`DDA9.1`). Replace or add those reasons.
- **Export compliance key.** Add `ITSAppUsesNonExemptEncryption: NO` under `info.properties`.
- **More screenshots.** Only the empty drop-zone state can be reached without clicking. With one image loaded, better shots would be: the developed print with a caption, the style picker, and the export and share options.
- **Copyright string.** Info.plist says `Copyright © 2026 Mark Studios.`, the store metadata says `2026 Mark Studios LLC`, and `LICENSE` is MIT © Mark Santos. Align them.

## How the screenshot was made (to retake it after the rename)

1. Build: `xcodebuild -project Polaroid.xcodeproj -scheme Polaroid -configuration Release -destination 'platform=macOS' -derivedDataPath <scratch> CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=com.nosleeplab.Polaroid.storeshots build`. This gives clean preferences, so Mark's real recent items and Desktop never show up.
2. Before launch, run `defaults write com.nosleeplab.Polaroid.storeshots autoWatchDesktop -bool false`. Otherwise, a screenshot saved to the Desktop while the app is running would make it **activate and take the screen** (`bringMainWindowForward`).
3. `open -g` the app, find the window id with Quartz by pid, run `screencapture -x -o -l<id>`, then compose on 2880×1800 with the icon's maroon colour and an SF Pro headline using PIL. Quit with SIGTERM; `osascript … to quit` did not quit the scratch build.

Method: wiki `concepts/macos-app-launch-test-without-the-screen.md`.
