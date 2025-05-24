import SwiftUI
import Highlightr

struct SettingsView: View {
    @AppStorage(TextDocument.autosaveKey) private var autosaveEnabled = true
    @AppStorage(TextDocument.themeKey) private var selectedTheme = "default"
    private let themes = ["default", "atom-one-dark", "monokai", "solarized-dark", "dracula"]

    var body: some View {
        Form {
            Toggle("Enable Autosave", isOn: $autosaveEnabled)
            Picker("Syntax Highlighting Theme", selection: $selectedTheme) {
                ForEach(themes, id: \.self) { theme in
                    Text(theme.capitalized).tag(theme)
                }
            }
            .onChange(of: selectedTheme) { _, _ in
                NotificationCenter.default.post(name: .NSThemeChanged, object: nil)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
