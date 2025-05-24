/* 
    AUTHOR: David P. Rush 
    COPYRIGHT: 2025 MIT 
    DATE: 20250524
    PURPOSE: Defines the document model, handling file reading/writing, language detection, 
    and settings persistence. Integrates with iCloud for settings sync and supports multiple file types.
*/

import SwiftUI
import UniformTypeIdentifiers

// Represents a document in the text editor, conforming to FileDocument for macOS document-based apps.
struct TextDocument: FileDocument {
    // The text content of the document.
    var text: String
    // Indicates if the document is a Markdown file, used for enabling Markdown preview.
    var isMarkdown: Bool
    // The programming language for syntax highlighting (e.g., "swift", "bash").
    var language: String
    // UserDefaults key for storing autosave preference.
    static let autosaveKey = "autosaveEnabled"
    // UserDefaults key for storing the selected Highlightr theme.
    static let themeKey = "highlightrTheme"
    // UserDefaults key for storing iCloud sync preference.
    static let iCloudSyncKey = "iCloudSyncEnabled"

    // Initializes a new document with optional default values.
    init(text: String = "", isMarkdown: Bool = false, language: String = "plain") {
        self.text = text
        self.isMarkdown = isMarkdown
        self.language = language
    }

    // Specifies the file types the app can read (plain text, Markdown, shell scripts, Swift, Python).
    static var readableContentTypes: [UTType] { [.plainText, .markdown, .shellScript, .swift, .pythonScript] }

    // Initializes a document from a file, reading its contents and determining its type.
    init(configuration: ReadConfiguration) throws {
        // Attempts to read the file's contents as UTF-8 text.
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            // Throws an error if the file cannot be read or decoded.
            throw CocoaError(.fileReadCorruptFile)
        }
        // Sets the document's text content.
        text = string
        // Determines if the file is Markdown based on its content type.
        isMarkdown = configuration.file.contentType == .markdown
        // Detects the programming language for syntax highlighting.
        language = detectLanguage(from: configuration.file.contentType)
    }

    // Writes the document's content to a file.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Converts the text to UTF-8 data.
        let data = text.data(using: .utf8)!
        // Returns a file wrapper containing the data.
        return FileWrapper(regularFileWithContents: data)
    }

    // Manages the autosave setting, syncing with both UserDefaults and iCloud.
    static var autosaveEnabled: Bool {
        get {
            // Retrieves the autosave setting from UserDefaults.
            UserDefaults.standard.bool(forKey: autosaveKey)
        }
        set {
            // Updates UserDefaults with the new value.
            UserDefaults.standard.set(newValue, forKey: autosaveKey)
            // Syncs the setting to iCloud for cross-device consistency.
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: autosaveKey)
        }
    }

    // Manages the Highlightr theme setting, syncing with UserDefaults and iCloud.
    static var highlightrTheme: String {
        get {
            // Retrieves the theme from UserDefaults, defaulting to "default" if not set.
            UserDefaults.standard.string(forKey: themeKey) ?? "default"
        }
        set {
            // Updates UserDefaults with the new theme.
            UserDefaults.standard.set(newValue, forKey: themeKey)
            // Syncs the theme to iCloud.
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: themeKey)
        }
    }

    // Manages the iCloud sync setting, syncing with UserDefaults and iCloud.
    static var iCloudSyncEnabled: Bool {
        get {
            // Retrieves the iCloud sync setting from UserDefaults.
            UserDefaults.standard.bool(forKey: iCloudSyncKey)
        }
        set {
            // Updates UserDefaults with the new value.
            UserDefaults.standard.set(newValue, forKey: iCloudSyncKey)
            // Syncs the setting to iCloud.
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: iCloudSyncKey)
        }
    }

    // Detects the programming language based on the file's content type.
    private func detectLanguage(from contentType: UTType?) -> String {
        switch contentType {
        case .markdown: return "markdown"
        case .shellScript: return "bash"
        case .swift: return "swift"
        case .pythonScript: return "python"
        default: return "plain"
        }
    }
}

// Extends UTType to define custom content types for Swift and Python files.
extension UTType {
    // Defines a UTType for Swift source files.
    static let swift = UTType(filenameExtension: "swift", conformingTo: .sourceCode)!
    // Defines a UTType for Python scripts.
    static let pythonScript = UTType(filenameExtension: "py", conformingTo: .sourceCode)!
}
