# PRD — Mac Share Full UI (SwiftUI)

Repo: https://github.com/imrj05/MacShare
Base: Swift 99.8%, macOS menu-bar app. Current state: menu-bar icon only, receive-to-Downloads, Finder share extension to send, QR code for Android pairing, mDNS-based LAN discovery, notification-driven accept flow.

## Problem
No real app UI. All interaction happens via macOS notifications + menu-bar dropdown. No visibility into transfer history, no in-app device rename, no discoverability control surfaced, no send-via-app flow (send only via Finder share sheet).

## Goal
Ship a native macOS SwiftUI app window with: Settings, Sidebar nav, Accept/Decline transfer sheet, Recent Transfers list, live Progress screen, theme toggle, device-name editor, discoverability show/hide toggle, QR send/receive screen, in-app file picker to send to a discovered device. Full Apple Human Interface Guidelines (HIG) compliance, SF Symbols only, native macOS 14+ idioms (NavigationSplitView, sidebar-adaptable toolbar, Settings scene).

## Non-goals
- No protocol changes (BLE, WebRTC-over-internet). UI layer only.
- No Windows/Linux receiver.
- No iOS companion app (out of scope this cycle).

## Users
- Mac users receiving files from Android Quick Share.
- Users occasionally sending files/links from Mac to Android without going through Finder share sheet.

## Core Screens & Requirements

### 1. Sidebar (NavigationSplitView)
- Sections: Devices (nearby, live mDNS list), Transfers (Recent), Settings.
- SF Symbols: `wifi`, `clock.arrow.circlepath`, `gearshape`.
- Selected state uses macOS accent color; supports keyboard nav (arrow keys) per HIG.
- Sidebar collapsible via toolbar `sidebar.left` button.

### 2. Accept/Decline (incoming transfer)
- Triggered same moment as current notification; notification stays (system-level alert) but tapping it — or app being foreground — surfaces an in-app sheet/banner.
- Shows: sender device name/icon, file count, total size, per-file names+types (SF Symbol per file type: `doc`, `photo`, `film`, `link`).
- Two buttons: Accept (primary, `checkmark.circle.fill`), Decline (`xmark.circle`, destructive style `.red`).
- PIN confirmation code shown per existing protocol (PROTOCOL.md) — large monospaced digits, must match device.
- Auto-decline timeout indicator (ring countdown) matching Android's UI expectation window.

### 3. Recent Transfers
- List, grouped by day ("Today", "Yesterday", date headers) — matches Finder/Messages pattern.
- Row: file icon/thumbnail, name, size, direction (`arrow.down.circle` receive / `arrow.up.circle` send), peer device name, timestamp, status badge (Completed/Failed/Declined).
- Row actions (swipe or context menu): Show in Finder, Delete from list, Retry (failed only).
- Empty state: SF Symbol `tray`, "No transfers yet."
- Search field in toolbar (filters by filename/device).

### 4. Progress Screen
- Per-active-transfer card: circular determinate `ProgressView` (SF style), speed (MB/s), ETA, file name, cancel button (`xmark.circle.fill`).
- Multiple concurrent transfers stack as cards.
- Live-updating; reflect actual bytes-transferred from transfer session object.
- Completion transitions card into Recent Transfers with brief checkmark animation.

### 5. Settings (macOS `Settings` scene, tabbed, matches System Settings pattern)
Tabs, each own pane:
- **General**: Theme toggle (System/Light/Dark segmented control), Launch at Login toggle, menu-bar icon visibility toggle.
- **Device**: Device name field (editable, defaults to current Mac hostname), device visibility avatar/icon picker if protocol supports.
- **Visibility**: Discoverability toggle ("Visible to everyone on your network" — existing limitation from README surfaced here as help text), Show/Hide toggle, optional "Visible for 5 min then hide" timer per Nearby Share convention.
- **Receiving**: Save-to-folder picker (default Downloads), "Ask before accepting" toggle (always on given protocol, shown as informational/disabled).
- **QR Code**: displays existing pairing QR full-size, regenerate/copy link button.
- **About**: version, PROTOCOL.md link, GitHub link, license (Unlicense).

### 6. QR Send/Receive Screen
- Receive tab: large QR (current mechanism — `https://quickshare.google/qrcode#key=...`), instructions text ("Scan with Google Files / Quick Share on Android"), copy-link button.
- Send tab: not applicable to Google protocol scan-in reverse; instead surfaces device-picker for sending (see #7). Screen tab-switches via segmented control, SF Symbol `qrcode`.

### 7. Send Flow (new — file picker → device)
- "+" button in sidebar toolbar (`plus.circle.fill`) → NSOpenPanel file picker (multi-select) → device picker sheet (list of discovered nearby devices, live mDNS) → send → Progress Screen.
- Mirrors existing Share Extension logic; new UI is a first-class in-app entry point (extension continues to work independently for Finder-integrated flow).

## Success Criteria
- All flows keyboard- and VoiceOver-accessible.
- Zero custom chrome — system materials (`.regularMaterial`), no custom title bars.
- App passes Apple's Human Interface Guidelines review informally: correct SF Symbol weights, correct control sizes (`.controlSize(.regular)`), Dynamic Type support.
- Dark mode / Light mode / System — instant, no relaunch.
- Settings persist via `@AppStorage` / UserDefaults, keyed to not collide with existing `NearbyShare`/`MacShare` module state.

## Constraints
- Must integrate with existing `NearbyShare` module (mDNS advertise/browse, protocol state machine) without rewriting transport layer.
- Existing Share Extension target unaffected.
- macOS 13+ minimum (NavigationSplitView requires 13+; project currently unconfirmed min-target — flag for xcodeproj check).

## Open Questions
- Does current `NearbyShare` module expose a Combine/async stream for discovered devices, or needs bridging layer for SwiftUI `@Observable`? → verify in `NearbyShare/` source before implementation.
- Confirm min deployment target in `MacShare.xcodeproj` project.plist before using `NavigationSplitView` (13+) / `@Observable` macro (14+).
