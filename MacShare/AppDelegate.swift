import Cocoa
import CoreText
import SwiftUI
import UserNotifications
import MacShareKit

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, MainAppDelegate {
    static var shared: AppDelegate?
    static var _store: MacShareStore?

    static func setStore(_ store: MacShareStore) {
        _store = store
        store.applyAppearance()
        shared?.setMenuBarIconVisible(store.showMenuBarIcon)
    }

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    override init() {
        super.init()
        AppDelegate.shared = self
        registerBundledFonts()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Apply the saved appearance before any window exists so the first frame is
        // already correct, and so System genuinely follows the OS.
        NSApp.appearance = MacShareStore.persistedAppearanceMode.nsAppearance
        setupMenuBar()
        setupNotifications()
        NearbyConnectionManager.shared.mainAppDelegate = self
        NearbyConnectionManager.shared.becomeVisible()
        DispatchQueue.main.async {
            self.openMainWindow()
        }
    }

    private func registerBundledFonts() {
        guard let fontURL = Bundle.main.url(forResource: "Manrope", withExtension: "ttf", subdirectory: "Fonts") else { return }
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let statusImage = NSImage(named: "MenuBarIcon")
        statusImage?.isTemplate = true
        statusItem?.button?.image = statusImage
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(togglePopover)
        statusItem?.behavior = .removalAllowed
        statusItem?.isVisible = AppDelegate._store?.showMenuBarIcon ?? true
    }

    func setMenuBarIconVisible(_ visible: Bool) {
        statusItem?.isVisible = visible
    }

    @objc private func togglePopover() {
        guard let store = AppDelegate._store else { return }
        if let popover, popover.isShown {
            popover.performClose(nil)
            self.popover = nil
            return
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 520)
        popover.behavior = .transient
        popover.animates = true

        let view = MenuBarPopoverView(
            onOpenMain: { [weak self] in
                self?.closePopoverAndOpenMain()
            },
            onOpenSettings: { [weak self] in
                self?.closePopoverAndOpenSettings()
            }
        )

        popover.contentViewController = NSHostingController(rootView: view.environment(store))
        self.popover = popover
        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func closePopoverAndOpenMain() {
        popover?.performClose(nil)
        popover = nil
        openMainWindow()
    }

    private func closePopoverAndOpenSettings() {
        popover?.performClose(nil)
        popover = nil
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc func openMainWindow() {
        let window = NSApplication.shared.windows.first(where: { $0.canBecomeMain }) ?? NSApplication.shared.windows.first
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Notifications

    private func setupNotifications() {
        let nc = UNUserNotificationCenter.current()
        nc.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if !granted {
                DispatchQueue.main.async {
                    self.showNotificationsDeniedAlert()
                }
            }
        }
        nc.delegate = self

        let incomingTransfersCategory = UNNotificationCategory(
            identifier: "INCOMING_TRANSFERS",
            actions: [
                UNNotificationAction(identifier: "ACCEPT", title: NSLocalizedString("Accept", comment: ""), options: .authenticationRequired),
                UNNotificationAction(identifier: "DECLINE", title: NSLocalizedString("Decline", comment: ""))
            ],
            intentIdentifiers: []
        )
        let errorsCategory = UNNotificationCategory(identifier: "ERRORS", actions: [], intentIdentifiers: [])
        nc.setNotificationCategories([incomingTransfersCategory, errorsCategory])
    }

    func showNotificationsDeniedAlert() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = NSLocalizedString("NotificationsDenied.Title", value: "Notification Permission Required", comment: "")
        alert.informativeText = NSLocalizedString("NotificationsDenied.Message", value: "Mac Share needs to be able to display notifications for incoming file transfers. Please allow notifications in System Settings.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("NotificationsDenied.OpenSettings", value: "Open settings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Quit", value: "Quit Mac Share", comment: ""))
        let result = alert.runModal()
        if result == NSApplication.ModalResponse.alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
        } else if result == NSApplication.ModalResponse.alertSecondButtonReturn {
            NSApplication.shared.terminate(nil)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let transferID = response.notification.request.content.userInfo["transferID"] as? String else {
            completionHandler()
            return
        }
        if response.actionIdentifier == "ACCEPT" {
            AppDelegate._store?.acceptIncomingTransfer(id: transferID)
        } else if response.actionIdentifier == "DECLINE" {
            AppDelegate._store?.declineIncomingTransfer(id: transferID)
        }
        completionHandler()
    }

    // MARK: - MainAppDelegate (NearbyConnectionManager callbacks)

    func obtainUserConsent(for transfer: TransferMetadata, from device: RemoteDeviceInfo) {
        let store = AppDelegate._store
        let deviceInfo = DiscoveredDevice(
            id: device.id ?? UUID().uuidString,
            name: device.name,
            deviceType: mapDeviceType(device.type)
        )

        let fileInfos = transfer.files.map { FileInfo(name: $0.name, size: $0.size, savedURL: $0.destinationURL) }
        let totalBytes = fileInfos.reduce(Int64(0)) { $0 + $1.size }

        let request = IncomingTransferRequest(
            transferID: transfer.id,
            device: deviceInfo,
            files: fileInfos,
            pinCode: transfer.pinCode ?? "000000",
            totalBytes: totalBytes
        )

        DispatchQueue.main.async {
            store?.presentIncomingRequest(request)
            self.openMainWindow()
        }

        let content = UNMutableNotificationContent()
        content.title = "Mac Share"
        content.subtitle = String(
            format: NSLocalizedString("PinCode", value: "PIN: %@", comment: ""),
            transfer.pinCode ?? "000000"
        )
        content.body = String(
            format: NSLocalizedString("DeviceSendingFiles", value: "%1$@ is sending you %2$@", comment: ""),
            device.name,
            request.displayName
        )
        content.sound = .default
        content.categoryIdentifier = "INCOMING_TRANSFERS"
        content.userInfo = ["transferID": transfer.id]
        if #available(macOS 11.0, *) {
            MSNotificationCenterHackery.removeDefaultAction(content)
        }
        let notificationRequest = UNNotificationRequest(
            identifier: "transfer_" + transfer.id,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(notificationRequest)
    }

    func incomingTransfer(id: String, progress: Double) {
        DispatchQueue.main.async {
            AppDelegate._store?.updateIncomingTransfer(id: id, progress: progress)
        }
    }

    func incomingTransfer(id: String, didFinishWith error: Error?) {
        let store = AppDelegate._store

        DispatchQueue.main.async {
            store?.finishIncomingTransfer(id: id, error: error)
            UNUserNotificationCenter.current().removeDeliveredNotifications(
                withIdentifiers: ["transfer_" + id]
            )
        }
    }

    // MARK: - Transfer Actions

    func acceptTransfer(transferID: String) {
        NearbyConnectionManager.shared.submitUserConsent(transferID: transferID, accept: true)
    }

    func declineTransfer(transferID: String) {
        NearbyConnectionManager.shared.submitUserConsent(transferID: transferID, accept: false)
    }

    // MARK: - Helpers

    private func mapDeviceType(_ type: RemoteDeviceInfo.DeviceType) -> DeviceType {
        switch type {
        case .phone: return .phone
        case .tablet: return .tablet
        case .computer: return .computer
        case .unknown: return .unknown
        }
    }
}
