/* 
    AUTHOR: David P. Rush 
    COPYRIGHT: 2025 MIT 
    DATE: 20250524
    PURPOSE: Defines the app’s structure, sets up the document-based architecture, 
    customizes the menu bar, and provides a settings scene. Initializes the CloudSyncManager 
    to handle iCloud synchronization and ensures all views have access to it.
*/

import SwiftUI

// The main entry point for the SimpleTextEditor macOS application, defining the app's structure and behavior.
@main
struct SimpleTextEditorApp: App {
    // State object to manage iCloud synchronization for documents and settings, ensuring persistence across app launches.
    @StateObject private var cloudSyncManager = CloudSyncManager()

    // Defines the app's scene, which is the top-level UI structure in SwiftUI.
    var body: some Scene {
        // DocumentGroup creates a document-based app, handling file operations (new, open, save) for TextDocument instances.
        DocumentGroup(newDocument: TextDocument()) { file in
            // ContentView is the main editor UI, receiving a binding to the document for two-way data updates.
            ContentView(document: file.$document)
                // Injects the cloudSyncManager as an environment object, making it accessible to ContentView and its children.
                .environmentObject(cloudSyncManager)
        }
        // Customizes the macOS menu bar by adding or replacing commands.
        .commands {
            // Replaces the default "New" menu item with a custom version, preserving standard Cmd+N behavior.
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    // Creates a new document using the shared NSDocumentController.
                    NSDocumentController.shared.newDocument(nil)
                }
                // Assigns the standard Cmd+N keyboard shortcut for familiarity.
                .keyboardShortcut("n", modifiers: [.command])
            }
            // Replaces the default "Save" menu item, relying on DocumentGroup's built-in save functionality.
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    // Save action is handled automatically by DocumentGroup; this is a placeholder for menu consistency.
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
            // Replaces the default "Open" menu item to trigger the file open dialog.
            CommandGroup(replacing: .openItem) {
                Button("Open...") {
                    // Opens the file picker using NSDocumentController.
                    NSDocumentController.shared.openDocument(nil)
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            // Adds a custom "Text" menu with editing commands (Find, Replace, Font Size adjustments).
            CommandMenu("Text") {
                // Find command to show the native find bar in the editor.
                Button("Find...") {
                    // Posts a notification to trigger the find bar in CodeTextView.
                    NotificationCenter.default.post(name: .NSFindPanelAction, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command])
                // Replace command, also triggering the find bar (same UI handles both).
                Button("Replace...") {
                    NotificationCenter.default.post(name: .NSReplacePanelAction, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])
                // Increases the font size in the editor.
                Button("Increase Font Size") {
                    NotificationCenter.default.post(name: .NSIncreaseFontSize, object: nil)
                }
                .keyboardShortcut("+", modifiers: [.command])
                // Decreases the font size in the editor.
                Button("Decrease Font Size") {
                    NotificationCenter.default.post(name: .NSDecreaseFontSize, object: nil)
                }
                .keyboardShortcut("-", modifiers: [.command])
            }
            // Adds a custom "Export" menu for saving documents in various formats.
            CommandMenu("Export") {
                // Exports the document as HTML with syntax highlighting.
                Button("Export as HTML") {
                    NotificationCenter.default.post(name: .NSExportHTML, object: nil)
                }
                // Exports the document as a PDF, preserving formatting.
                Button("Export as PDF") {
                    NotificationCenter.default.post(name: .NSExportPDF, object: nil)
                }
                // Exports the document as plain Markdown.
                Button("Export as Markdown") {
                    NotificationCenter.default.post(name: .NSExportMarkdown, object: nil)
                }
                // Exports the document as RTF, including syntax highlighting.
                Button("Export as RTF") {
                    NotificationCenter.default.post(name: .NSExportRTF, object: nil)
                }
            }
        }
        // Defines a Settings scene for user preferences (autosave, theme, iCloud sync).
        Settings {
            // SettingsView is the UI for configuring app preferences.
            SettingsView()
                // Injects the cloudSyncManager to enable iCloud sync toggling.
                .environmentObject(cloudSyncManager)
        }
    }
}

// Extension to define custom notification names used for inter-component communication.
extension NSNotification.Name {
    // Notification for showing the find bar.
    static let NSFindPanelAction = NSNotification.Name("NSFindPanelAction")
    // Notification for showing the replace functionality (uses same find bar).
    static let NSReplacePanelAction = NSNotification.Name("NSReplacePanelAction")
    // Notification to increase editor font size.
    static let NSIncreaseFontSize = NSNotification.Name("NSIncreaseFontSize")
    // Notification to decrease editor font size.
    static let NSDecreaseFontSize = NSNotification.Name("NSDecreaseFontSize")
    // Notification for when the syntax highlighting theme changes.
    static let NSThemeChanged = NSNotification.Name("NSThemeChanged")
    // Notifications for export actions.
    static let NSExportHTML = NSNotification.Name("NSExportHTML")
    static let NSExportPDF = NSNotification.Name("NSExportPDF")
    static let NSExportMarkdown = NSNotification.Name("NSExportMarkdown")
    static let NSExportRTF = NSNotification.Name("NSExportRTF")
}
