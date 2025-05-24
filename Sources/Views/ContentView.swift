/* 
    AUTHOR: David P. Rush 
    COPYRIGHT: 2025 MIT 
    DATE: 20250524
    PURPOSE: Defines the main editor UI, integrating the text editor (CodeTextView), Markdown preview, 
    linting feedback, and export functionality. Manages autosave and updates linting on text changes.
*/

import SwiftUI
import AppKit
import Down
import WebKit
import PDFKit

// The main editor UI, displaying the text editor, Markdown preview, and toolbar.
struct ContentView: View {
    // Binding to the document, allowing two-way updates to its text and properties.
    @Binding var document: TextDocument
    // Access to the undo manager for supporting undo/redo operations.
    @Environment(\.undoManager) var undoManager
    // Environment object for managing iCloud synchronization.
    @EnvironmentObject var cloudSyncManager: CloudSyncManager
    // State to toggle the Markdown preview visibility.
    @State private var showMarkdownPreview: Bool = false
    // Timer for periodic autosaving, initialized when autosave is enabled.
    @State private var timer: Timer? = nil
    // Stores linting errors to display in the toolbar and editor.
    @State private var lintErrors: [String] = []

    // Defines the view's layout and behavior.
    var body: some View {
        // HSplitView allows horizontal resizing between the editor and preview (if visible).
        HSplitView {
            // VSplitView stacks the editor and Markdown preview vertically.
            VSplitView {
                // CodeTextView is the custom editor component, handling text input, syntax highlighting, and linting.
                CodeTextView(text: $document.text, language: document.language, undoManager: undoManager, lintErrors: $lintErrors)
                    .frame(minWidth: 200)
                    .padding()
                    // Initializes autosave when the view appears.
                    .onAppear {
                        if TextDocument.autosaveEnabled {
                            startAutosave()
                        }
                        // Performs initial linting on the document.
                        lintDocument()
                    }
                    // Cleans up the timer when the view disappears.
                    .onDisappear {
                        timer?.invalidate()
                    }
                    // Updates the autosave timer based on the autosave setting.
                    .onChange(of: TextDocument.autosaveEnabled) { _, enabled in
                        if enabled {
                            startAutosave()
                        } else {
                            timer?.invalidate()
                        }
                    }
                    // Re-lints the document whenever its text changes.
                    .onChange(of: document.text) { _, _ in
                        lintDocument()
                    }
                // Shows the Markdown preview if enabled and the document is Markdown.
                if showMarkdownPreview && document.isMarkdown {
                    WebView(markdown: document.text)
                        .frame(minWidth: 200)
                        .padding()
                }
            }
        }
        // Adds a toolbar with status information and controls.
        .toolbar {
            // Displays the character count of the document.
            ToolbarItem(placement: .status) {
                Text("\(document.text.count) characters")
            }
            // Displays the number of linting issues, if any, in red.
            ToolbarItem(placement: .status) {
                if !lintErrors.isEmpty {
                    Text("\(lintErrors.count) linting issues")
                        .foregroundColor(.red)
                }
            }
            // Toggle for enabling/disabling the Markdown preview, shown only for Markdown files.
            ToolbarItem(placement: .automatic) {
                if document.isMarkdown {
                    Toggle("Markdown Preview", isOn: $showMarkdownPreview)
                }
            }
            // Export menu for saving the document in various formats.
            ToolbarItem(placement: .automatic) {
                Menu("Export") {
                    Button("Export as HTML") { exportAsHTML() }
                    Button("Export as PDF") { exportAsPDF() }
                    Button("Export as Markdown") { exportAsMarkdown() }
                    Button("Export as RTF") { exportAsRTF() }
                }
            }
        }
    }

    // Starts the autosave timer, saving the document every 5 seconds.
    private func startAutosave() {
        // Invalidates any existing timer to prevent duplicates.
        timer?.invalidate()
        // Creates a new timer that triggers a save notification periodically.
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            NotificationCenter.default.post(name: .NSDocumentDidChangeNotification, object: nil)
        }
    }

    // Performs linting on the document, updating the lintErrors state.
    private func lintDocument() {
        lintErrors = Linter.lint(text: document.text, language: document.language)
    }

    // Exports the document as an HTML file with syntax highlighting.
    private func exportAsHTML() {
        // Initializes Highlightr for syntax highlighting.
        guard let highlighter = Highlightr() else { return }
        // Sets the current theme for consistent styling.
        highlighter.setTheme(to: TextDocument.highlightrTheme)
        // Generates HTML with syntax highlighting.
        let html = highlighter.highlight(document.text, as: document.language, fastRender: false)?.htmlString
        // Creates a save panel for the user to choose the output location.
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = "export.html"
        // Shows the save panel and writes the HTML if confirmed.
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? html?.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    // Exports the document as a PDF, preserving formatting.
    private func exportAsPDF() {
        // Retrieves the NSTextView from the window for rendering.
        guard let textView = NSApp.keyWindow?.contentView?.subviews.first(where: { $0 is NSScrollView })?.subviews.first(where: { $0 is NSTextView }) as? NSTextView else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "export.pdf"
        // Shows the save panel and generates a PDF if confirmed.
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let printInfo = NSPrintInfo.shared
                let operation = NSPrintOperation(view: textView, printInfo: printInfo)
                operation.printInfo.destinationURL = url
                operation.printInfo.printer = NSPrinter(name: "PDF")
                operation.run()
            }
        }
    }

    // Exports the document as a Markdown file.
    private func exportAsMarkdown() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.markdown]
        panel.nameFieldStringValue = "export.md"
        // Writes the plain text to a .md file if confirmed.
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? document.text.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    // Exports the document as an RTF file, including syntax highlighting.
    private func exportAsRTF() {
        // Retrieves the NSTextView to access its attributed string.
        guard let textView = NSApp.keyWindow?.contentView?.subviews.first(where: { $0 is NSScrollView })?.subviews.first(where: { $0 is NSTextView }) as? NSTextView,
              let rtfData = textView.textStorage?.rtf(from: NSRange(location: 0, length: textView.textStorage?.length ?? 0))
        else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.rtf]
        panel.nameFieldStringValue = "export.rtf"
        // Writes the RTF data to a file if confirmed.
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? rtfData.write(to: url)
            }
        }
    }
}

// Renders Markdown content as HTML in a WKWebView for the preview.
struct WebView: NSViewRepresentable {
    // The Markdown text to render.
    let markdown: String

    // Creates a WKWebView for displaying the rendered HTML.
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        updateNSView(webView, context: context)
        return webView
    }

    // Updates the WKWebView with the latest Markdown content.
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Converts Markdown to HTML using the Down library.
        let down = Down(markdownString: markdown)
        if let html = try? down.toHTML() {
            // Loads the HTML into the web view.
            nsView.loadHTMLString(html, baseURL: nil)
        }
    }
}
