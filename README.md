# Snippy

A menu-bar text expander for macOS. Type a short trigger anywhere and it expands into the full text.

## Run it (Xcode — recommended now that it's installed)

```
open Package.swift
```

Xcode opens the folder as a project. Press **Cmd+R** to build and run — you get breakpoints, the console, and SwiftUI previews on the views under `Sources/Snippy/`.

## Run it (command line)

```
swift run
```

## Package it as a real .app

Needed for three things: `Launch at Login` (Settings tab) only works from a proper bundle, macOS won't index a loose executable as an app, and Accessibility grants need a stable code signature to survive across rebuilds.

```
./scripts/build_app.sh          # debug build
./scripts/build_app.sh release  # release build
open Snippy.app
```

It signs with a local "Snippy Development" certificate (created once in Keychain Access — self-signed root, Code Signing type, trust set to Always Trust) instead of an ad-hoc signature, so Accessibility doesn't need to be re-granted after every rebuild.

## First run

Click the keyboard icon in the menu bar → **Grant Accessibility Access**. Snippy needs this to see keystrokes system-wide and to type the expansion back in. This is a one-time grant you do yourself in System Settings.

## Sync

Snippets live at `~/Library/Mobile Documents/com~apple~CloudDocs/Snippy/snippets.json` — plain iCloud Drive, no Apple Developer account or entitlements needed since Snippy isn't sandboxed. A directory watcher reloads the store whenever that file changes underneath the running app, whether from iCloud syncing down a change from another Mac or from Snippy's own save. If iCloud Drive isn't available, it falls back to local-only storage under Application Support.

## Dynamic tokens

An expansion isn't limited to plain text. Supported tokens:

- `{date}` / `{time}` — current date/time at expansion.
- `{clipboard}` — whatever's currently on the clipboard.
- `{cursor}` — where the caret lands after expanding (e.g. `Hi {cursor},` leaves the cursor right after "Hi ").
- `{fill:Label}` — pauses expansion and shows a small panel prompting for a value first. The same label used twice fills both spots with the same answer.

## Where things stand

- **Phase 1** — expansion engine, permission onboarding, local JSON storage. Done.
- **Phase 2** — menu bar UI: add/edit/delete snippets grouped by folder, settings tab with launch-at-login. Done.
- **Phase 3** — sync across Macs via iCloud Drive. Done.
- **Phase 4** — dynamic tokens: date/time, clipboard, cursor placement, prompted fill-ins. Done.
