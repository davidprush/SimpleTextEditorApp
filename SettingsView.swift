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
        textView.isEditable = false
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let sampleCode = """
        // Sample Swift code
        let greeting = "Hello, World!"
        print(greeting)
        """
        textView.string = sampleCode

        let highlighter = Highlightr()
        highlighter?.setTheme(to: theme)
        if let attributedString = highlighter?.highlight(sampleCode, as: "swift") {
            textView.textStorage?.setAttributedString(attributedString)
        }

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            let highlighter = Highlightr()
            highlighter?.setTheme(to: theme)
            if let attributedString = highlighter?.highlight(textView.string, as: "swift") {
                textView.textStorage?.setAttributedString(attributedString)
            }
        }
    }
}
