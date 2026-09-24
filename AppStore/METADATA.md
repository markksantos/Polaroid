# Instant Frame — Mac App Store metadata

Drafted 2026-09-22 from the source code and README on branch `appstore-kit`. Character counts were computed by script, and the script fails if any field is over Apple's limit. **⚠ MARK'S DECISION** marks a field only Mark can settle.

| Field | Value | Chars / limit |
|---|---|---|
| App name | Instant Frame (Mark's decision, 2026-09-24) | 13 / 30 |
| Subtitle | Screenshots into instant film | 29 / 30 |
| Bundle ID | `com.nosleeplab.Polaroid` (the bundle ID never appears in the store, so it can stay) | — |
| Version / build | 1.0.0 (1) — from project.yml | — |
| SKU | INSTANTFRAME-MAC-001 (any unique string; Mark can change it) | — |
| Primary category | Graphics & Design (matches `LSApplicationCategoryType` in Info.plist) | — |
| Secondary category | Photography **⚠ MARK'S DECISION** | — |
| Price | **⚠ MARK'S DECISION.** The README suggests a one-time USD 9. There's no in-app purchase code. | — |
| Copyright | 2026 Mark Studios LLC | — |
| Support URL | https://nosleeplab.com/support (live, general NoSleepLab support page with a contact email) | — |
| Privacy Policy URL | https://nosleeplab.com/privacy (live, general NoSleepLab policy covering all its apps) | — |
| Marketing URL (optional) | NOT YET PUBLISHED - needs a page (no NoSleepLab page exists for this app) | — |
| Minimum macOS | 14.0 · universal binary (x86_64 + arm64, confirmed with lipo on the Release build) | — |

**About the name:** Mark chose `Instant Frame` on 2026-09-24. The app's old working name is a registered trademark, so using it in the name, subtitle, keywords, screenshots or the binary is a Guideline 5.2.1 (intellectual property) rejection, and the owner could file a takedown. Name check on 2026-09-24: the iTunes Search API Mac store query (`entity=macSoftware`) returned 135 results and none contains "Instant Frame". The iOS query (`entity=software`) returned HTTP 503 on every retry, so a web search of apps.apple.com stood in: it found only longer names such as "Vintage Photo Frames - Instant Frame Maker & Photo Editor", and "SnapFrame", once listed as "Instant Frame Maker". There's no exact match, but only creating the App Store Connect record confirms a name is free. `Shotframe` is **taken** (iOS). **The app itself was renamed on 2026-09-24** (`PRODUCT_NAME`, the window title, the menu bar item, the menus, every UI string, the default save folder `~/Pictures/Instant Frame` and the file name pattern `Instant Frame yyyy-MM-dd HH.mm.ss`). See CHECKLIST.

## Promotional text (156 / 170)

Turn any screenshot or photo into an instant-film print with a develop animation, a handwritten caption and real paper texture, then save, copy or share it.

## Description (1383 / 4000)

```text
Make a screenshot worth sharing.

Drop any image into Instant Frame, open one, or paste it from the clipboard, and it lands in a classic instant-film frame: a square photo, a thick bottom border and real paper grain. Then it develops, fading from warm sepia into full colour.

WRITE ON IT
• Add a caption of up to 60 characters in the bottom border
• Three handwriting fonts: Marker Felt, Bradley Hand and Chalkduster
• Six ink colours, from black and navy to faded blue and pencil gray
• Alignment, height and size controls, plus caption suggestions and one-click uppercase, lowercase and title case
• An optional date stamp taken from the image's creation date

MAKE IT YOURS
• Four paper finishes: clean white, aged cream, worn and cool gray, each generated on your Mac
• Soft, standard or dramatic shadow
• A slight random tilt, or keep it straight
• Randomize the whole look in one click

SHARE IT FAST
• Save a PNG to your Pictures folder, or pick any folder you like
• Copy the image, or its file path, to the clipboard
• Open the macOS share sheet
• Export the full frame or the photo alone, on a transparent or matte background, at 1080 px, 1920 px or the original size

ALWAYS NEARBY
A menu bar item keeps your recent prints, a paste button and a quick import one click away.

PRIVATE BY DESIGN
No accounts, no analytics and no network access. Your images stay on your Mac.
```

**Deliberately left out of the copy: "auto-watch Desktop screenshots"**, even though the README leads with it. With the app's real entitlements, a sandbox probe was **denied** access to `~/Desktop` (errno 1). The app never asks for the folder on first run, so on a fresh install the watcher fails without any message, and App Review would find a headline feature that does nothing. There's also a code bug: after the user picks a watch folder, the saved bookmark is resolved on the next launch but `startAccessingSecurityScopedResource()` is never called for the watcher. So even once the user chooses the folder, watching should stop after the next relaunch (found by reading the code; not verified at runtime). **Put the claim back only after that fix** (see CHECKLIST). The old `AppStore/metadata.md` (now renamed to this file, and still in git history) claimed it, and also used the trademarked old name in the name and keywords.

## Keywords (97 / 100)

```text
instant film,photo frame,screenshot,caption,handwriting,vintage,retro,paper,snapshot,print,border
```

No spaces after commas. No competitor or trademarked names (checked against: the trademarked old name and a competing Mac app that uses it, Instax, Fujifilm, Kodak, Instagram, Apple). Leaves out words Apple already indexes from the name and category.

## URLs — what was checked (curl, 2026-09-22)

- `https://nosleeplab.com/privacy` returns **200**. The general policy says the apps collect no personal data, have no analytics, no ads, and keep data local. That matches this app.
- `https://nosleeplab.com/support` returns **200**. It has a contact email (Guideline 1.5 is met).
- The old-name app paths (`/apps/<old name>` and `/<old name>`) return **404**. `sitemap.xml` lists 23 app pages and none of them is this app. **No app-specific page exists yet.** When one is made, title it Instant Frame and keep the old name out of its title and URL.
- The only link inside the app is the NoSleepLab link in Settings (`https://nosleeplab.com`), which opens in the browser when clicked.
- The pages are branded **NoSleepLab**, the bundle ID is `com.nosleeplab.*`, and the copyright is **Mark Studios LLC**. Confirm they're consistent (**⚠ MARK'S DECISION**).

## Age rating questionnaire

Every answer is the 'None' / 'No' option, which gives a **4+** rating:

- In-app controls: Parental Controls **No** · Age Assurance **No**
- Capabilities: Unrestricted Web Access **No** · User-Generated Content **No** (captions stay on the Mac and are never shared with other users) · Messaging and Chat **No** · Advertising **No**
- Mature themes · Profanity or crude humor · Horror/fear themes · Alcohol, tobacco or drug use or references · Sexual content or nudity · Graphic sexual content and nudity: **None**
- Cartoon or fantasy violence · Realistic violence · Prolonged graphic or sadistic realistic violence · Guns or other weapons: **None**
- Simulated gambling · Contests · Gambling · Loot boxes: **None / No**
- Medical or treatment information · Health or wellness topics: **None**

## App Privacy ('nutrition label') draft

**Answer: "Data Not Collected"** for every data type. This is based on the code:

- **No network:** the entitlements are `app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.app-scope` and `assets.pictures.read-write`. There's no `network.client`. A sandbox probe signed with these exact entitlements got `BLOCKED -1003` on an HTTPS request.
- **No SDKs, analytics or accounts:** the project has no Swift packages, and a grep found no `URLSession`. `PrivacyInfo.xcprivacy` has `NSPrivacyTracking=false` and no collected data types, and the file is inside the built bundle.
- **Files:** it reads images the user opens, drops or pastes, and writes PNGs to `~/Pictures/Instant Frame` by default, creating the folder on the first save. On 2026-09-24 a probe ran the app's own save code with the app's exact entitlements in a fresh container: it created the folder and wrote the PNG, and `~/Developer` was denied as a control. Recent-item thumbnails go in the app's own container.
- **⚠ Privacy-manifest reason code to fix:** the manifest declares file-timestamp reason `C617.1`, which only covers files *inside the app container*. The app reads `creationDate` of **user-picked images** and **shows it** as the date stamp, so the matching reasons are `3B52.1` (user-granted files) and `DDA9.1` (displayed to the user). Upload validation won't catch this. It's a correctness fix for whoever owns the code.

## Export compliance

`ITSAppUsesNonExemptEncryption` is **not set** in Info.plist, so App Store Connect will ask on every upload. The answer is **No**: the app uses no encryption and has no network access. Adding the key to `project.yml` under `info.properties` would stop the question.

## ⚠ Decisions only Mark can make

- **App name**: decided on 2026-09-24. It's `Instant Frame`, and the app is renamed to match.
- **Price**: the README suggests USD 9 one-time.
- **Secondary category**: Photography, or none.
- **Brand consistency**: NoSleepLab site and bundle prefix vs the Mark Studios LLC copyright.
- **App icon**: the 1024 px icon is a full white square with the maroon shape cut off at the right and bottom edges (see CHECKLIST).
