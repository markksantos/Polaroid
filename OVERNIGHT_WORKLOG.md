# Polaroid — Overnight Worklog

## What it is

A native macOS SwiftUI app (Swift 6, macOS 14+) that converts screenshots into styled
Polaroid frames: programmatic paper textures, a develop animation (sepia → color),
handwritten captions with ink/font/alignment controls, a date stamp, and one-click
export (save / save-as / copy / share). It auto-watches the Desktop for new screenshots,
supports drag/drop/paste, has a menu-bar extra with recent items, and persists settings.
Targets the Mac App Store as a one-time purchase. Built with XcodeGen (`project.yml`),
no third-party dependencies, fully sandboxed, no network calls.

Bundle ID `com.nosleeplab.Polaroid`. Author-tracked git repo with one prior commit.

## Starting state

Honest starting completeness: **~80%** (triage said 75%).

The codebase was already substantial, coherent, and high-quality — not a scaffold and not
a third-party clone. All core systems were genuinely implemented and well-architected:
- `PolaroidRenderer` (Core Graphics compositor with scaled metrics, 3 export sizes, 2 frame modes)
- `PaperTextureGenerator` (seeded-random grain/scuffs/warm-corners, 4 textures) + `PaperTextureStore`
- `ExportService` (PNG encode, save/save-as/copy/share, recent thumbnails, unique filenames)
- `ScreenshotWatcher` (DispatchSource file watcher, screenshot-name filtering)
- `PolaroidDocumentModel` (the @MainActor @Observable controller wiring everything)
- Full SwiftUI view layer (drop zone, polaroid + develop animation, caption editor,
  style picker, settings, menu-bar content)
- App icons (full set incl. 1024px), App Store screenshots (6 × 2880×1800), metadata.md,
  PrivacyInfo.xcprivacy, entitlements, README, LICENSE.

What was actually missing was the last-mile production/App-Store hardening and verification:
the generated `.xcodeproj` had to be produced, version metadata was inconsistent, the
screenshot generator was non-deterministic, test coverage was thin, and there was no
CLAUDE.md or CI-style verify script.

## What I changed, fixed, added, built

**1. Fixed App Store version metadata (real bug).**
`Polaroid/Resources/Info.plist` hard-coded `CFBundleShortVersionString = 1.0` and
`CFBundleVersion = 1`, diverging from `MARKETING_VERSION = 1.0.0` in `project.yml` and the
"1.0.0" shown in `SettingsView` and `AppStore/metadata.md`. Worse, the XcodeGen `info`
block had no `properties`, so every `xcodegen generate` overwrote the plist with defaults
(this is what kept reverting manual edits). Moved the keys into
`targets.Polaroid.info.properties` in `project.yml` so XcodeGen generates them correctly:
- `CFBundleShortVersionString -> $(MARKETING_VERSION)` (now resolves to 1.0.0)
- `CFBundleVersion -> $(CURRENT_PROJECT_VERSION)`
- `LSApplicationCategoryType -> public.app-category.graphics-design` (App Store category was missing)
- `LSMinimumSystemVersion -> $(MACOSX_DEPLOYMENT_TARGET)` (14.0)
- `NSHumanReadableCopyright` (set)
Verified the resolved values in the built Release bundle's Info.plist.
Commit `6a4ab3d`.

**2. Fixed non-deterministic screenshot generator (real bug).**
`AppStore/generate_screenshots.swift` declared a 2880×1800 canvas but rendered via
`NSImage.lockFocus()`, which honors the display backing scale — on this Retina Mac it
produced 5760×3600 PNGs (above the Mac App Store max screenshot size, and inconsistent
with the committed assets). Rewrote the render loop to draw into an explicit 1×
`NSBitmapImageRep`, guaranteeing exact 2880×1800 output on any machine. Output now matches
the committed screenshots byte-for-byte and re-runs reproducibly. Commit `000a22f`.

**3. Expanded test coverage 11 → 21 (all passing).**
Added `PolaroidTests/ExportServiceTests.swift` (saveAs writes a valid sized PNG, renderPNG
handles a 1px source without crashing, copy populates the pasteboard, ExportError messages
are user-readable) and `PolaroidTests/AppSettingsTests.swift` (recentPolaroids capped at 5,
filename-pattern preview + empty fallback, save-directory bookmark fallback,
resetToDefaults, captureDefaults round-trip). Updated README count. Commit `33dc276`.

**4. Added CLAUDE.md and Scripts/verify.sh.**
`CLAUDE.md` documents architecture, the XcodeGen build model (project.yml is the source of
truth; `.xcodeproj` and `Info.plist` are generated), build/run/verify commands, the App
Store submission path, and conventions. `Scripts/verify.sh` is a one-command local gate:
generate → test → Release build → analyze → regenerate screenshots, no code signing.
Commit `a38490c`.

**Decisions made:**
- Kept the generated `.xcodeproj` tracked in git (it was tracked in the initial commit and
  the README tells users to `open Polaroid.xcodeproj` right after clone). Did NOT gitignore
  it, to stay consistent with the author's choice. `build/` and DerivedData remain ignored.
- Did not touch the entitlements/sandbox config — it's already minimal and correct (app
  sandbox, Pictures read-write, user-selected read-write, app-scope bookmarks; no network).

## Current state

- **Builds?** Yes. Debug and Release both `BUILD SUCCEEDED`, from a clean DerivedData.
  Universal binary `x86_64 arm64`. Zero compiler warnings; clang static analyzer clean.
- **Runs?** Yes. Smoke-launched the Release `.app` — process starts, no crash reports, quits
  cleanly. (Full interactive UX — drop image, develop, caption, export — is implemented;
  not exercised headlessly because it's a GUI app, but all paths build and the renderer is
  unit-tested.)
- **Tests?** 21/21 pass.
- **App Store metadata** resolves correctly in the built bundle: version 1.0.0, build 1,
  category graphics-design, min-system 14.0.

## How to run it locally

```bash
brew install xcodegen            # one time
cd /Users/markksantos/Developer/Polaroid
xcodegen generate
open Polaroid.xcodeproj           # select the Polaroid scheme, Cmd+R
```

Or from the terminal (no signing):

```bash
xcodebuild -project Polaroid.xcodeproj -scheme Polaroid \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO build
open build/.../Release/Polaroid.app   # or run from Xcode
```

Full local gate: `./Scripts/verify.sh`.

## How to deploy (App Store — when ready)

Requires Mark's Apple Developer Program enrollment + App Store Connect (see NEEDS FROM MARK).

1. (Optional) bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml`, then
   `xcodegen generate`.
2. Open `Polaroid.xcodeproj` in Xcode. Select the **Polaroid** target → Signing &
   Capabilities → set **Team** (Automatic signing). Pick destination **Any Mac**.
3. Product → **Archive**.
4. In the Organizer: **Distribute App → App Store Connect → Upload** (or export and use
   Transporter). The privacy label is "no data collected" (`PrivacyInfo.xcprivacy`); confirm
   no network entitlements are present.
5. In App Store Connect, create the app record (name "Polaroid", category Graphics & Design,
   one-time purchase ~$9), attach the 6 screenshots from `AppStore/Screenshots/`, and paste
   copy from `AppStore/metadata.md`. Submit for review.

This task did NOT deploy anything (deploy-ready only, per instructions).

## NEEDS FROM MARK

1. **Apple Developer Program enrollment + App Store Connect access** for `com.nosleeplab`.
   Required for code signing, archiving for distribution, and submission. Without it the app
   can only be built/run locally (ad-hoc signed), which it does today.
2. **Code signing identity / Team** — "Automatic" signing needs a provisioning profile from
   the Apple account. Local builds use ad-hoc signing (`CODE_SIGNING_ALLOWED=NO`).
3. **Support / marketing URL decision** — metadata + Settings currently point at
   `https://nosleeplab.com`. Confirm that domain is live, or swap it before submission.
4. (Minor) Confirm the App Store price point ($9 is suggested in README/metadata).

## Honest completeness now and what remains

**~92%.** The app is functionally complete, builds cleanly as a universal binary, passes a
21-test suite + static analysis, runs without crashing, and has correct, consistent App
Store metadata + assets. It is deploy-READY pending only Mark's Apple account.

What remains (all gated on Mark or out of scope for an unattended run):
- Signing + archive + upload (needs the Apple Developer account — #1/#2 above).
- A real on-device pass of the interactive flow (drop → develop animation → caption →
  export → menu-bar recents) on Mark's machine; logic is unit-tested but the GUI wasn't
  driven headlessly here.
- Optional polish that was explicitly out of scope for safety: notarization/distribution
  config, and confirming the nosleeplab.com support URL is live.

## QA Verification

Verified by independent QA reviewer (not the build agent) on 2026-06-01.

### Commands run

```
xcodegen generate
xcodebuild ... Debug build  → BUILD SUCCEEDED
xcodebuild ... test         → Executed 21 tests, with 0 failures
xcodebuild ... Release build → BUILD SUCCEEDED
xcodebuild ... analyze      → ANALYZE SUCCEEDED
lipo -info Polaroid.app/Contents/MacOS/Polaroid
plutil -p Polaroid.app/Contents/Info.plist (key spot-check)
```

### Results

- Debug build: BUILD SUCCEEDED, zero errors, zero warnings.
- Release build: BUILD SUCCEEDED, zero errors, zero warnings.
- Tests: 21/21 pass (AppSettingsTests 6, ExportServiceTests 4, PolaroidRendererTests 9, ScreenshotWatcherTests 2). Counts match the worklog claim exactly.
- Static analysis: ANALYZE SUCCEEDED, no findings.
- Universal binary confirmed: x86_64 + arm64 fat binary in the Release product.
- Built Info.plist values independently verified: CFBundleShortVersionString=1.0.0, CFBundleVersion=1, LSApplicationCategoryType=public.app-category.graphics-design, LSMinimumSystemVersion=14.0, NSHumanReadableCopyright set.
- project.yml info.properties block present and correct — XcodeGen is the source of truth for all plist keys.
- generate_screenshots.swift uses explicit NSBitmapImageRep (not lockFocus) — deterministic 2880x1800 fix verified in source.

### Discrepancies found

None. All build-agent claims check out:
- Version metadata fix is real and verified in the built bundle.
- Screenshot determinism fix is implemented correctly in source.
- 21 tests exist and all pass.
- CLAUDE.md and Scripts/verify.sh are present.
- Universal binary is genuine.

### No fix applied

No build-breaking issues found; no commits were needed.

### Remaining issues (not introduced by overnight agent)

- No Apple Developer account — cannot sign, archive, or submit to the Mac App Store.
- nosleeplab.com support/marketing URL (referenced in metadata.md and SettingsView) is unverified.
- Interactive GUI flow (drop image → develop animation → caption → export) was not driven headlessly; unit tests cover the logic but a manual smoke-test on Mark's machine is recommended before submission.
