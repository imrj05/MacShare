import AppKit
import Combine
import Sparkle

/// Owns the app's single Sparkle updater and exposes a small, SwiftUI-friendly
/// surface for the "Check for Updates…" menu item and the Settings pane.
///
/// Sparkle is configured through the app's Info.plist (SUFeedURL, SUPublicEDKey,
/// SUEnableAutomaticChecks, SUScheduledCheckInterval), so this type only has to
/// start the updater and forward the user's manual check / preference.
final class UpdaterController: ObservableObject {
    static let shared = UpdaterController()

    /// False while Sparkle is already checking or installing an update. Drives
    /// the enabled state of the menu item and the buttons.
    @Published private(set) var canCheckForUpdates = false

    /// Mirrors `SPUUpdater.automaticallyChecksForUpdates`. Sparkle persists the
    /// value in the app's user defaults, so we only forward changes to it.
    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set {
            objectWillChange.send()
            controller.updater.automaticallyChecksForUpdates = newValue
        }
    }

    /// The marketing version of the running build, for the Settings row.
    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private let controller: SPUStandardUpdaterController
    private var canCheckObservation: NSKeyValueObservation?
    private var hasStarted = false

    private var updater: SPUUpdater { controller.updater }

    private init() {
        // Start the updater explicitly in `start()` (from
        // applicationDidFinishLaunching) so that a misconfigured bundle is
        // reported by Sparkle's standard alert rather than during app init.
        let controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.controller = controller
        self.canCheckForUpdates = controller.updater.canCheckForUpdates
        self.canCheckObservation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            let value = updater.canCheckForUpdates
            DispatchQueue.main.async {
                guard let self, self.canCheckForUpdates != value else { return }
                self.canCheckForUpdates = value
            }
        }
    }

    /// Starts Sparkle's scheduler once, from `applicationDidFinishLaunching`.
    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        controller.startUpdater()
    }

    /// The user-facing "Check for Updates…" action.
    func checkForUpdates() {
        start()
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }
}
