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
