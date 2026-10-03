import SwiftUI

@main
struct MacShareApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store = MacShareStore()

    var body: some Scene {
        Window("Mac Share", id: "main") {
            AppShell()
                .environment(store)
                .font(AppFont.body)
                .tint(AppColors.accent)
                .frame(minWidth: AppStyle.Layout.sidebarWidth + AppStyle.Layout.detailMinWidth,
                       minHeight: AppStyle.Layout.detailMinHeight)
                .onAppear {
                    AppDelegate.setStore(store)
                }
        }
        .defaultSize(width: 1080, height: 720)
        .windowResizability(.automatic)
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environment(store)
                .font(AppFont.body)
                .tint(AppColors.accent)
                .frame(minWidth: 560, minHeight: 620)
        }
    }
}
