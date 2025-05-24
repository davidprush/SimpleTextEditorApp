import SwiftUI

@main
struct SimpleTextEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NSDocumentController.shared.newDocument(nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    // Handled by DocumentGroup
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
            CommandGroup(replacing: .openItem) {
                Button("Open...") {
                    NSDocumentController.shared.openDocument(nil)
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            CommandMenu("Text") {
                Button("Find...") {
                    NotificationCenter.default.post(name: .NSFindPanelAction, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command])
                Button("Replace...") {
                    NotificationCenter.default.post(name: .NSReplacePanelAction, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])
                Button("Increase Font Size") {
                    NotificationCenter.default.post(name: .NSIncreaseFontSize, object: nil)
                }
                .keyboardShortcut("+", modifiers: [.command])
                Button("Decrease Font Size") {
                    NotificationCenter.default.post(name: .NSDecreaseFontSize, object: nil)
                }
                .keyboardShortcut("-", modifiers: [.command])
            }
            CommandMenu("Export") {
                Button("Export as HTML") { NotificationCenter.default.post(name: .NSExportHTML, object: nil) }
                Button("Export as PDF") { NotificationCenter.default.post(name: .NSExportPDF, object: nil) }
                Button("Export as Markdown") { NotificationCenter.default.post(name: .NSExportMarkdown, object: nil) }
                Button("Export as RTF") { NotificationCenter.default.post(name: .NSExportRTF, object: nil) }
            }
        }
        Settings {
            SettingsView()
        }
    }
}

extension NSNotification.Name {
    static let NSFindPanelAction = NSNotification.Name("NSFindPanelAction")
    static let NSReplacePanelAction = NSNotification.Name("NSReplacePanelAction")
    static let NSIncreaseFontSize = NSNotification.Name("NSIncreaseFontSize")
    static let NSDecreaseFontSize = NSNotification.Name("NSDecreaseFontSize")
    static let NSThemeChanged = NSNotification.Name("NSThemeChanged")
    static let NSExportHTML = NSNotification.Name("NSExportHTML")
    static let NSExportPDF = NSNotification.Name("NSExportPDF")
    static let NSExportMarkdown = NSNotification.Name("NSExportMarkdown")
    static let NSExportRTF = NS estouNotification.Name("NSExportRTF")
}
