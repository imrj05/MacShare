# Design Spec — Mac Share Full UI (SwiftUI / Apple HIG)

Companion to PRD.md. Repo: https://github.com/imrj05/MacShare

## Design Language
- 100% native AppKit-via-SwiftUI idioms. No custom-drawn chrome.
- Materials: `.regularMaterial` for sidebar/toolbar backgrounds, `.ultraThinMaterial` for overlay sheets.
- Corner radius: 10pt (cards), 8pt (buttons/rows) — matches macOS 14/15 system radii.
- Spacing grid: 8pt base unit (8/16/24/32).
- Typography: SF Pro (system default), Dynamic Type via `.font(.title2)`, `.headline`, `.body`, `.caption` semantic styles — never fixed point sizes.
- Color: system semantic colors only — `.primary`, `.secondary`, `Color.accentColor`, `.red` for destructive. No custom hex palette (respects user's macOS accent color choice).
- Icons: SF Symbols exclusively, weight `.medium` default, `.semibold` for primary actions.

## App Shell
```
NavigationSplitView {
    SidebarView()          // min width 220
} detail: {
    NavigationStack {
        DetailView(for: selection)
    }
}
.navigationSplitViewStyle(.balanced)
```
Toolbar: standard `.toolbar { ToolbarItem }`, sidebar toggle auto-provided by `NavigationSplitView`.

## Screen Specs

### Sidebar
```
List(selection: $selectedSection) {
    Section("Nearby") {
        ForEach(discoveredDevices) { device in
            Label(device.name, systemImage: "laptopcomputer")
                .badge(device.isBusy ? "Sending" : nil)
        }
    }
    Section {
        NavigationLink(value: Section.transfers) {
            Label("Recent Transfers", systemImage: "clock.arrow.circlepath")
        }
        NavigationLink(value: Section.settings) {
            Label("Settings", systemImage: "gearshape")
        }
    }
}
.listStyle(.sidebar)
```
- Discovered devices update live off mDNS browse callback → bridge to `@Published`/`@Observable` array.
- Row icon reflects device type if protocol reports it (`laptopcomputer` / `iphone` / generic `desktopcomputer`); fallback generic PC icon since Android devices report type in payload — map to closest SF Symbol (`ipad`, `iphone`, `pc` fallback `desktopcomputer`).

### Accept/Decline Sheet
```
.sheet(isPresented: $showingIncoming) {
    VStack(spacing: 16) {
        Image(systemName: "arrow.down.circle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.tint)
        Text(senderName).font(.headline)
        Text("wants to send \(fileCount) file(s) · \(totalSize)")
            .font(.subheadline).foregroundStyle(.secondary)
        ForEach(files) { f in
            Label(f.name, systemImage: f.symbolName)
                .font(.callout)
        }
        Text(pinCode)
            .font(.system(.largeTitle, design: .monospaced, weight: .bold))
        HStack {
            Button("Decline", role: .destructive) { decline() }
                .buttonStyle(.bordered)
            Button("Accept") { accept() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }
    .padding(24)
    .frame(width: 360)
}
```
- Countdown ring: `ProgressView(value: remaining, total: timeout)` styled `.progressViewStyle(.circular)` overlaid top-right corner, small.
- Sheet is modal to app window; system notification remains as OS-level fallback if app not frontmost (unchanged from current behavior).

### Recent Transfers
```
List {
    ForEach(groupedByDay) { group in
        Section(group.dateLabel) {
            ForEach(group.items) { item in
                TransferRow(item: item)
            }
        }
    }
}
.searchable(text: $query)
.overlay { if items.isEmpty { ContentUnavailableView("No Transfers", systemImage: "tray") } }
```
`TransferRow`:
```
HStack {
    Image(systemName: item.symbolName).frame(width: 28)
    VStack(alignment: .leading) {
        Text(item.filename).font(.body)
        Text("\(item.peerName) · \(item.sizeString)").font(.caption).foregroundStyle(.secondary)
    }
    Spacer()
    Image(systemName: item.direction == .incoming ? "arrow.down.circle" : "arrow.up.circle")
        .foregroundStyle(.secondary)
    StatusBadge(status: item.status)  // colored capsule: green Completed, red Failed, gray Declined
}
.contextMenu {
    Button("Show in Finder", systemImage: "folder") { reveal(item) }
    if item.status == .failed { Button("Retry", systemImage: "arrow.clockwise") { retry(item) } }
    Button("Remove", systemImage: "trash", role: .destructive) { remove(item) }
}
```
`ContentUnavailableView` requires macOS 14+ — flag against deployment target.

### Progress Screen
- Presented as a stack of cards, either inline top-of-list in Transfers view, or dedicated overlay while active (design choice: inline banner stack above Recent Transfers list, HIG-consistent with Mail/Messages "sending" banners).
```
VStack(alignment: .leading, spacing: 6) {
    HStack {
        Text(transfer.filename).font(.callout).bold()
        Spacer()
        Button { cancel(transfer) } label: {
            Image(systemName: "xmark.circle.fill")
        }.buttonStyle(.plain).foregroundStyle(.secondary)
    }
    ProgressView(value: transfer.progress)
        .progressViewStyle(.linear)
    HStack {
        Text("\(transfer.speedString)/s").font(.caption).foregroundStyle(.secondary)
        Spacer()
        Text(transfer.etaString).font(.caption).foregroundStyle(.secondary)
    }
}
.padding(12)
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
```
On completion: `.transition(.opacity.combined(with: .move(edge: .top)))`, animate into Recent Transfers list.

### Settings (macOS `Settings` scene)
```
Settings {
    TabView {
        GeneralSettingsView().tabItem { Label("General", systemImage: "gearshape") }
        DeviceSettingsView().tabItem { Label("Device", systemImage: "desktopcomputer") }
        VisibilitySettingsView().tabItem { Label("Visibility", systemImage: "eye") }
        ReceivingSettingsView().tabItem { Label("Receiving", systemImage: "tray.and.arrow.down") }
        QRSettingsView().tabItem { Label("QR Code", systemImage: "qrcode") }
        AboutSettingsView().tabItem { Label("About", systemImage: "info.circle") }
    }
    .frame(width: 480)
}
```
Matches System Settings tab-bar pattern (icon+label, ~76pt tab width, window non-resizable width, resizable height per pane).

**General pane:**
```
Form {
    Picker("Appearance", selection: $appearanceMode) {
        Text("System").tag(AppearanceMode.system)
        Text("Light").tag(AppearanceMode.light)
        Text("Dark").tag(AppearanceMode.dark)
    }
    .pickerStyle(.segmented)
    Toggle("Launch at Login", isOn: $launchAtLogin)
    Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
}
.formStyle(.grouped)
```
Theme applied via `.preferredColorScheme(appearanceMode.colorScheme)` at root `WindowGroup`/`Settings` scene level; `system` → `nil` (inherits).

**Device pane:**
```
Form {
    TextField("Device Name", text: $deviceName)
        .textFieldStyle(.roundedBorder)
    Text("This name is shown to nearby devices.")
        .font(.caption).foregroundStyle(.secondary)
}
```
- Persist via `@AppStorage("deviceName")`; on change, push into `MacShareKit` advertise payload (requires mDNS TXT record update — verify module supports live rename without full re-advertise restart).

**Visibility pane:**
```
Form {
    Toggle("Visible to nearby devices", isOn: $isDiscoverable)
    if isDiscoverable {
        Picker("Visibility duration", selection: $visibilityWindow) {
            Text("Always").tag(VisibilityWindow.always)
            Text("5 minutes").tag(VisibilityWindow.fiveMin)
        }
    }
    Text("When visible, your Mac appears to everyone on your local network. [Learn more](#)")
        .font(.caption).foregroundStyle(.secondary)
}
```
- `isDiscoverable = false` → stop mDNS advertise (browse for incoming can continue or also stop, per product call — recommend also stopping advertise only, keep listening socket for direct sends if protocol allows).

**Receiving pane:**
```
Form {
    LabeledContent("Save to") {
        HStack {
            Text(saveFolder.lastPathComponent)
            Button("Choose…") { chooseFolder() }
        }
    }
    Toggle("Ask before accepting", isOn: .constant(true)).disabled(true)
}
```

**QR Code pane:**
```
VStack(spacing: 16) {
    Image(nsImage: qrImage)
        .interpolation(.none)
        .resizable().frame(width: 220, height: 220)
    Text("Scan with Google Files or Quick Share on Android")
        .font(.caption).foregroundStyle(.secondary)
    Button("Copy Link", systemImage: "doc.on.doc") { copyLink() }
}
```

**About pane:**
```
VStack(spacing: 8) {
    Image(nsImage: appIcon).resizable().frame(width: 64, height: 64)
    Text("Mac Share").font(.title2.bold())
    Text("Version \(version)").font(.caption).foregroundStyle(.secondary)
    Link("Protocol Documentation", destination: URL(string: "https://github.com/imrj05/MacShare/blob/main/PROTOCOL.md")!)
    Link("GitHub Repository", destination: URL(string: "https://github.com/imrj05/MacShare")!)
    Text("MIT License").font(.caption2).foregroundStyle(.secondary)
}
```

### Send Flow
1. Toolbar `+` (`plus.circle.fill`) → `NSOpenPanel` (`allowsMultipleSelection = true`).
2. On selection → sheet `DevicePickerView`: `List` of live discovered devices (reuse sidebar's device source), row = `Label(device.name, systemImage: icon)`, tap → confirm.
3. Push transfer → same session/progress pipeline as Share Extension uses today (`MacShareKit` connection classes) → Progress Screen card appears.

## State/Data Bridging Notes
- Wrap existing `MacShareKit` discovery/session callback APIs (likely delegate- or closure-based, pre-SwiftUI) in an `@Observable` (macOS 14+) or `ObservableObject` (13+) coordinator class exposing: `discoveredDevices: [Device]`, `activeTransfers: [Transfer]`, `incomingRequest: IncomingRequest?`.
- Recent Transfers needs persistence — not currently modeled (app is receive-and-forget to Downloads). Add lightweight `TransferRecord` struct + local JSON store or `SwiftData` model (macOS 14+) under app support directory; write record on transfer start/complete/fail.
- Device rename requires checking whether `MacShareKit` module's advertiser reads name dynamically or needs restart — inspect before wiring `TextField` directly to live advertise state.

## Accessibility
- All icon-only buttons get `.accessibilityLabel(...)`.
- Sheets use `.accessibilityAddTraits(.isModal)` implicitly via SwiftUI `.sheet`.
- Color is never sole status indicator — status badges pair color + text label ("Completed", not just green dot).
- Support Increase Contrast: rely on system materials/colors, no custom low-contrast pairs.

## Open Implementation Risks
- Confirm `MacShare.xcodeproj` deployment target ≥ macOS 14 before using `@Observable`/`ContentUnavailableView`/`SwiftData`; if target is 13, fall back to `ObservableObject`+`@Published`, custom empty-state view, JSON persistence instead of SwiftData.
- Menu-bar-only `LSUIElement` current behavior vs. new full window: decide whether app becomes regular Dock app or stays menu-bar-agent-with-optional-window (`NSApp.setActivationPolicy` toggle tied to "Show menu bar icon only" setting).
