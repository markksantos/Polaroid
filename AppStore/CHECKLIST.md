# Instant Frame — Mac App Store checklist

Status on 2026-09-22, updated 2026-09-24 for the rename (branch `appstore-kit`). Nothing has been submitted, signed or uploaded.
This kit lives in the existing `AppStore/` folder, not a new `appstore/`. This Mac's disk is case-insensitive, so `appstore/` and `AppStore/` are the same folder, and adding both casings to git would split the folder in two on case-sensitive checkouts. For the same reason, the old `metadata.md` was renamed with `git mv` to `METADATA.md` and rewritten; the old text is still in git history.

## Ready

- [x] **Metadata**: `METADATA.md` has all fields within Apple's limits (the generator script fails on any overage). It uses the chosen name `Instant Frame`.
- [x] **Screenshot**: `Screenshots/mac-2880x1800/01-drop-an-image.png` is 2880×1800 with no alpha. It's a real window capture. **Retaken on 2026-09-24 after the rename**: the title bar reads "Instant Frame". The window comes from a sandboxed Release build, and the Mac was in light mode, so the window is light now.
- [x] **Icon set**: **redrawn on 2026-09-24** (see below). All 10 macOS slots are filled from one 1024×1024 master, and the build compiles them into `AppIcon.icns` and `Assets.car`.
- [x] **Sandbox**: on (user-selected read-write, app-scope bookmarks, Pictures read-write, and no network). A probe with these exact entitlements confirmed HTTPS is blocked. On 2026-09-24 a probe ran the app's own first-launch save code with the same entitlements in a fresh container: it created `~/Pictures/Instant Frame` and wrote the PNG there, and `~/Developer` was denied as a control.
- [x] **Privacy manifest**: present and inside the built bundle. The reason code needs a fix; see below.
- [x] **Build**: the Release build is clean and a **universal binary** (x86_64 + arm64). It launched hidden, rendered its window and quit with no crash report.
- [x] **Support and privacy URLs**: both are live (general NoSleepLab pages).

## Blocks submission, in order

1. ✅ **Renamed to Instant Frame (2026-09-24).** The old working name is a registered trademark (Guideline 5.2.1), and App Review sees the binary as well as the listing. What changed: `PRODUCT_NAME` is `Instant Frame` (the `.app` name, the menu bar app name, About and Quit), plus `CFBundleDisplayName`, the window title, the menu bar extra, every UI string (a finished image is now a "print", as in "New Print…" and "Recent Prints"), the frame-mode label ("Full frame"), the default save folder `~/Pictures/Instant Frame`, the default file name `Instant Frame yyyy-MM-dd HH.mm.ss` and the store screenshot.
   - Kept on purpose: the bundle ID `com.nosleeplab.Polaroid` (it never appears in the store), the Swift module (`PRODUCT_MODULE_NAME: Polaroid`, so `@testable import` still works), and internal type, file, target and scheme names.
   - Also fixed: Settings and "Copy path" used to show the save folder through the sandbox container path, which contains the bundle ID. The Pictures symlink is now resolved, so they show `~/Pictures/Instant Frame`.
   - Only on a Mac that ran an earlier build: a file-name pattern saved in Settings before the rename keeps its old prefix. Fresh installs aren't affected.
2. **🔴 Desktop watcher fails in the sandbox without telling anyone.** `autoWatchDesktop` defaults to **on** and watches `NSHomeDirectory()/Desktop`. Under the sandbox that's the container's Desktop symlink, and a probe with the app's entitlements was **denied** (errno 1). On a fresh install the watcher does nothing, and **Rescan Desktop** (in the menu bar item, the toolbar menu and Settings) shows "Desktop scan failed". A reviewer who tries the feature the old README leads with will see it fail (Guideline 2.1). There's also a second bug: `updateWatcher()` resolves the saved folder bookmark but never calls `startAccessingSecurityScopedResource()`, so a folder the user picked should stop being watched after the next relaunch (found by reading the code, not run). Fix: on first run, ask for the screenshots folder with an open panel and start security-scoped access before watching. Or default the watcher to off and hide Rescan until a folder is chosen. The listing copy already leaves this feature out.
3. **Apple Distribution certificate.** This Mac has only `Apple Development: Mark Santos`. Create an **Apple Distribution** cert and a **Mac Installer Distribution** cert (Xcode → Settings → Accounts; needs Mark's Apple ID).
4. **Signing team.** `DEVELOPMENT_TEAM` isn't set in `project.yml`. Set it with automatic signing, then run `xcodegen generate` (the `.xcodeproj` and `Info.plist` are generated).
5. **Register the bundle ID** `com.nosleeplab.Polaroid`. It never appears in the store, so it can stay. Automatic signing registers it.
6. **App Store Connect app record** under the new name, with bundle ID and SKU.
7. **Archive and upload** with the installed release **Xcode 27.0**.
8. **Fill in App Store Connect** from METADATA.md: price (README suggests USD 9), age rating (every answer None/No, giving 4+), App Privacy "Data Not Collected", export compliance "No", and the screenshots.

## Should fix before review (not upload blockers)

- **Don't upload the old `Screenshots/01…06-polaroid.png`.** `generate_screenshots.swift` *draws* them: a fake light-theme window, a fake photo, fake panels. The real window looks different and has a different toolbar. They advertise the Desktop auto-watch too. (They were regenerated on 2026-09-24 without the old name, but they're still drawn, not captured.) Store screenshots have to show the real app (Guideline 2.3.3). They're left in place because the README embeds `01-polaroid.png`.
- ✅ **Icon redrawn (2026-09-24).** The old art was a white opaque tile with tilted, layered rectangles, transparent holes and a maroon shape running off the edge; masking couldn't fix it. The new icon is drawn in code by `AppStore/generate_app_icon.py` (Pillow + NumPy at 4× supersampling, no image generation): an 824 px superellipse body (n = 5) centred on the 1,024 canvas, with a soft drop shadow and transparent corners. On it sits one instant print tilted 8°, with a cream frame, a thick bottom border and a sun-over-two-mountains photo. The colours are sampled from the old icon: maroon body, cream frame, sky blue, navy mountains, sun yellow. There's no text, no camera, no brand mark and no rainbow stripe. The script writes all 10 slots, and the file names come from `Contents.json`. Re-run it with `python3 AppStore/generate_app_icon.py`.
  - Verified: every slot has corner alpha 0, and the opaque body spans 101–922 on the 1024. A Release build compiled `AppIcon.icns` with 16, 32, 128 and 256 px, all at corner alpha 0, and `Assets.car` has all 10 renditions with `Opaque: false`. The bundle's `AppIcon` image, drawn at 1024, also has corner alpha 0.
  - 16 px: it still reads as a maroon tile holding a light print with a blue photo and a dark mountain band. The sun is a pixel or two, so it's decoration at that size, not the thing that identifies the icon. At 32 px the thick bottom border and the sun are both clear.
- **Privacy manifest reason code.** The file-timestamp reason `C617.1` only covers files inside the app container. The app reads the `creationDate` of images the user picked (`3B52.1`) and shows it as the date stamp (`DDA9.1`). Replace or add those reasons.
- **Export compliance key.** Add `ITSAppUsesNonExemptEncryption: NO` under `info.properties`.
- **More screenshots.** Only the empty drop-zone state can be reached without clicking. With one image loaded, better shots would be: the developed print with a caption, the style picker, and the export and share options.
- ✅ **Copyright string (2026-09-24).** `project.yml` and the generated `Info.plist` now read `Copyright © 2026 Mark Studios LLC. All rights reserved.`, which matches the store metadata (`2026 Mark Studios LLC`). `LICENSE` (the MIT source licence, © Mark Santos) wasn't changed.

## How the screenshot was made (2026-09-24, after the rename)

1. Run `xcodegen generate` in a scratch copy of the repo. Build it: `xcodebuild -project Polaroid.xcodeproj -scheme Polaroid -configuration Release -destination 'generic/platform=macOS' -derivedDataPath <scratch> CODE_SIGNING_ALLOWED=NO build`. The result is `Instant Frame.app`.
2. Give the build a scratch bundle ID with PlistBuddy (`com.nosleeplab.Polaroid.launchcheck`). Then sign it ad hoc with the app's entitlements: `codesign --force -s - --entitlements Polaroid/Polaroid.entitlements`. That gives it a fresh container and clean preferences. The sandbox also denies the Desktop watcher, so a new screenshot on the Desktop can't bring the window forward.
3. `open -g` the app, find its window by pid with Quartz, and run `screencapture -x -o -l<id>`. Then SIGTERM the exact pid.
4. Scale the 1960×1560 capture to 1633×1300 and paste it at (623, 410) over the previous composition with PIL. That composition has the same maroon background and SF Pro headline.
- An **unsigned** build isn't sandboxed and watches the real Desktop. `defaults write … autoWatchDesktop -bool false` does **not** turn the watcher off, because the app stores the setting as JSON data. That's why the step above uses a sandboxed build.

Method: wiki `concepts/macos-app-launch-test-without-the-screen.md`.
