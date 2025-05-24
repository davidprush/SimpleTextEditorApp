/* 
    AUTHOR: David P. Rush 
    COPYRIGHT: 2025 MIT 
    DATE: 20250524
    PURPOSE: Defines the settings UI, allowing users to configure autosave, iCloud sync, 
    and syntax highlighting themes. The theme preview enhances usability by showing the 
    visual effect of each theme.
*/

import SwiftUI
import AppKit
import Highlightr

struct SettingsView: View {
    @AppStorage(TextDocument.autosaveKey) private var autosaveEnabled = true
    @AppStorage(TextDocument.themeKey) private var selectedTheme = "default"
    @AppStorage(TextDocument.iCloudSyncKey) private var iCloudSyncEnabled = false
    @EnvironmentObject var cloudSyncManager: CloudSyncManager
    private let themes = ["default", "atom-one-dark", "monokai", "solarized-dark", "dracula"]

    var body: some View {
        Form {
            Toggle("Enable Autosave", isOn: $autosaveEnabled)
            Toggle("Enable iCloud Sync", isOn: $iCloudSyncEnabled)
                .disabled(!cloudSyncManager.iCloudAvailable)
            Picker("Syntax Highlighting Theme", selection: $selectedTheme) {
                ForEach(themes, id: \.self) { theme in
                    Text(theme.capitalized).tag(theme)
                }
            }
            .onChange(of: selectedTheme) { _, _ in
                NotificationCenter.default.post(name: .NSThemeChanged, object: nil)
            }
            ThemePreviewView(theme: selectedTheme)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

struct ThemePreviewView: NSViewRepresentable {
    let theme: String

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
