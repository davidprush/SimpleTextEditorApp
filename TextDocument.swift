import SwiftUI
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    var text: String
    var isMarkdown: Bool
    var language: String
    static let autosaveKey = "autosaveEnabled"
    static let themeKey = "highlightrTheme"
    static let iCloudSyncKey = "iCloudSyncEnabled"

    init(text: String = "", isMarkdown: Bool = false, language: String = "plain") {
        self.text = text
        self.isMarkdown = isMarkdown
        self.language = language
    }

    static var readableContentTypes: [UTType] { [.plainText, .markdown, .shellScript, .swift, .pythonScript] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
        isMarkdown = configuration.file.contentType == .markdown
        language = detectLanguage(from: configuration.file.contentType)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }

    static var autosaveEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autosaveKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: autosaveKey)
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: autosaveKey)
        }
    }

    static var highlightrTheme: String {
        get { UserDefaults.standard.string(forKey: themeKey) ?? "default" }
        set {
            UserDefaults.standard.set(newValue, forKey: themeKey)
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: themeKey)
        }
    }

    static var iCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: iCloudSyncKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: iCloudSyncKey)
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: iCloudSyncKey)
        }
    }

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

extension UTType {
    static let swift = UTType(filenameExtension: "swift", conformingTo: .sourceCode)!
    static let pythonScript = UTType(filenameExtension: "py", conformingTo: .sourceCode)!
}
