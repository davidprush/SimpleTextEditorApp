/* 
    AUTHOR: David P. Rush 
    COPYRIGHT: 2025 MIT 
    DATE: 20250524
    Purpose and Context
    Center of the text editor’s UI, wrapping an NSTextView to provide advanced text editing capabilities
    that SwiftUI’s TextEditor cannot match. It integrates:
        - Syntax Highlighting: Uses Highlightr to highlight code in languages like Swift, Python, Bash, and Markdown, with theme support.
        - Line Numbers: Displays a clickable gutter via LineNumberRulerView, allowing users to jump to specific lines.
        - Native Find Bar: Leverages NSTextView’s built-in find/replace functionality.
        - Linting Highlights: Underlines lines with syntax errors detected by the Linter.
        - Performance Optimization: Debounces Highlightr calls to handle large documents efficiently.
        - Font Size Adjustments: Responds to menu commands for increasing/decreasing font size.
    Interacts with:
        - TextDocument: For language and theme settings.
        - ContentView: Passes text and linting errors via bindings.
        - Linter: Uses error messages to highlight problematic lines.
        - SettingsView: Responds to theme changes via notifications.
*/

import SwiftUI
import AppKit
import Highlightr

// A SwiftUI view representable that wraps an NSTextView, providing advanced text editing with syntax highlighting, line numbers, linting, and a native find bar.
struct CodeTextView: NSViewRepresentable {
    // Binding to the document's text, enabling two-way updates between the UI and the document model.
    @Binding var text: String
    // The programming language for syntax highlighting (e.g., "swift", "bash", "markdown").
    let language: String
    // Optional undo manager for supporting undo/redo operations in the text view.
    var undoManager: UndoManager?
    // Binding to linting errors, used to highlight problematic lines in the editor.
    @Binding var lintErrors: [String]
    // State to track the current font size, adjustable via menu commands.
    @State private var fontSize: CGFloat = 14
    // State to store a DispatchWorkItem for debouncing syntax highlighting updates, improving performance.
    @State private var highlightWorkItem: DispatchWorkItem?

    // Creates the underlying NSScrollView containing the NSTextView and line number gutter.
    func makeNSView(context: Context) -> NSScrollView {
        // Initializes an NSTextView for text editing.
        let textView = NSTextView()
        // Ensures the text view is editable by the user.
        textView.isEditable = true
        // Disables rich text to maintain plain text with custom attributes (e.g., syntax highlighting).
        textView.isRichText = false
        // Enables undo support, integrating with the provided undoManager.
        textView.allowsUndo = true
        // Sets a monospaced font for code-like appearance, using the current font size.
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        // Assigns the coordinator as the text view's delegate to handle text changes and events.
        textView.delegate = context.coordinator
        // Enables the native macOS find bar for search and replace functionality.
        textView.usesFindBar = true
        // Supports incremental searching for a responsive find experience.
        textView.isIncrementalSearchingEnabled = true
        // Applies initial syntax highlighting to the text view.
        context.coordinator.applySyntaxHighlighting(to: textView)

        // Creates a custom LineNumberRulerView to display line numbers in a gutter.
        let gutterView = LineNumberRulerView(textView: textView) { line in
            // Callback to handle line number clicks, jumping to the specified line.
            context.coordinator.jumpToLine(line, in: textView)
        }
        // Wraps the text view in an NSScrollView for scrolling support.
        let scrollView = NSScrollView()
        // Sets the text view as the scroll view's document view.
        scrollView.documentView = textView
        // Enables vertical scrolling for long documents.
        scrollView.hasVerticalScroller = true
        // Enables horizontal scrolling for wide lines.
        scrollView.hasHorizontalScroller = true
        // Assigns the line number gutter as the vertical ruler view.
        scrollView.verticalRulerView = gutterView
        // Makes the ruler (gutter) visible.
        scrollView.rulersVisible = true

        // Registers the coordinator to listen for font size increase notifications.
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.increaseFontSize),
            name: .NSIncreaseFontSize,
            object: nil
        )
        // Registers the coordinator to listen for font size decrease notifications.
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.decreaseFontSize),
            name: .NSDecreaseFontSize,
            object: nil
        )
        // Registers the coordinator to listen for theme change notifications.
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.themeChanged),
            name: .NSThemeChanged,
            object: nil
        )
        // Registers the coordinator to listen for find bar activation (via Cmd+F).
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.showFindBar),
            name: .NSFindPanelAction,
            object: nil
        )
        // Registers the coordinator to listen for replace activation (via Cmd+R, uses same find bar).
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.showFindBar),
            name: .NSReplacePanelAction,
            object: nil
        )

        // Returns the configured scroll view containing the text view and gutter.
        return scrollView
    }

    // Updates the NSScrollView when the view's state or bindings change.
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Retrieves the NSTextView from the scroll view.
        if let textView = nsView.documentView as? NSTextView {
            // Updates the text view's content only if it differs from the bound text to avoid unnecessary updates.
            if textView.string != text {
                textView.string = text
            }
            // Updates the font size to reflect any changes.
            textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            // Reapplies syntax highlighting to ensure consistency with the current text and theme.
            context.coordinator.applySyntaxHighlighting(to: textView)
            // Updates the line number gutter to reflect any changes in line count.
            if let gutterView = nsView.verticalRulerView as? LineNumberRulerView {
                gutterView.updateLineNumbers()
            }
        }
    }

    // Creates a coordinator to manage NSTextView delegation and event handling.
    func makeCoordinator() -> Coordinator {
        // Initializes the coordinator with a reference to this view.
        Coordinator(self)
    }

    // Coordinator class to handle NSTextView delegate methods and notification responses.
    class Coordinator: NSObject, NSTextViewDelegate {
        // Reference to the parent CodeTextView for accessing its properties and bindings.
        var parent: CodeTextView
        // Highlightr instance for applying syntax highlighting to the text view.
        var highlighter: Highlightr?

        // Initializes the coordinator with the parent view.
        init(_ parent: CodeTextView) {
            self.parent = parent
            // Creates a Highlightr instance for syntax highlighting.
            self.highlighter = Highlightr()
            super.init()
        }

        // Called when the text view's content changes (e.g., user typing).
        func textDidChange(_ notification: Notification) {
            // Ensures the notification comes from an NSTextView.
            if let textView = notification.object as? NSTextView {
                // Updates the bound text to reflect the new content.
                parent.text = textView.string
                // Debounces syntax highlighting to improve performance.
                debounceHighlighting(for: textView)
                // Registers an undo action to revert the text change.
                parent.undoManager?.registerUndo(withTarget: textView) { tv in
                    tv.string = parent.text
                }
                // Updates the line number gutter to reflect the new line count.
                if let scrollView = textView.enclosingScrollView,
                   let gutterView = scrollView.verticalRulerView as? LineNumberRulerView {
                    gutterView.updateLineNumbers()
                }
            }
        }

        // Debounces syntax highlighting updates to reduce CPU usage for rapid text changes.
        func debounceHighlighting(for textView: NSTextView) {
            // Cancels any pending highlighting task to avoid redundant work.
            parent.highlightWorkItem?.cancel()
            // Creates a new work item to apply highlighting after a delay.
            let workItem = DispatchWorkItem { [weak self] in
                self?.applySyntaxHighlighting(to: textView)
            }
            // Stores the work item for cancellation if needed.
            parent.highlightWorkItem = workItem
            // Schedules the work item to run after a 0.3-second delay.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }

        // Applies syntax highlighting and linting highlights to the text view.
        func applySyntaxHighlighting(to textView: NSTextView) {
            // Ensures a valid Highlightr instance exists.
            guard let highlighter = highlighter else { return }
            // Sets the current theme from TextDocument settings.
            highlighter.setTheme(to: TextDocument.highlightrTheme)
            // Generates an attributed string with syntax highlighting for the specified language.
            if let attributedString = highlighter.highlight(textView.string, as: parent.language) {
                // Preserves the current cursor/selection position to avoid disrupting the user.
                let currentSelection = textView.selectedRanges
                // Applies the highlighted text to the text view.
                textView.textStorage?.setAttributedString(attributedString)
                // Restores the cursor/selection position.
                textView.setSelectedRanges(currentSelection)
                // Applies linting highlights (e.g., red underlines) for errors.
                applyLintingHighlights(to: textView)
            }
        }

        // Highlights lines with linting errors by adding red underlines.
        private func applyLintingHighlights(to textView: NSTextView) {
            let text = textView.string
            let lines = text.components(separatedBy: .newlines)
            // Iterates through linting errors to apply highlights.
            for error in parent.lintErrors {
                // Extracts the line number from the error message (e.g., "Line 5: ...").
                if let range = error.rangeOfLineNumber, range.location < lines.count {
                    // Determines the character range for the affected line.
                    let lineRange = (text as NSString).lineRange(for: NSRange(location: range.location, length: 0))
                    // Adds a red underline to indicate the error.
                    textView.textStorage?.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: lineRange)
                    textView.textStorage?.addAttribute(.underlineColor, value: NSColor.red, range: lineRange)
                }
            }
        }

        // Moves the cursor to the specified line, with visual feedback.
        func jumpToLine(_ line: Int, in textView: NSTextView) {
            let lines = textView.string.components(separatedBy: .newlines)
            // Ensures the line number is valid.
            guard line > 0 && line <= lines.count else { return }
            let lineIndex = line - 1
            // Calculates the character range for the target line.
            let lineRange = (textView.string as NSString).lineRange(for: NSRange(location: textView.string.lineRange(for: lineIndex).location, length: 0))
            // Selects the line and scrolls it into view.
            textView.setSelectedRange(lineRange)
            textView.scrollRangeToVisible(lineRange)
            // Briefly highlights the line with a semi-transparent yellow background.
            textView.textStorage?.addAttribute(.backgroundColor, value: NSColor.yellow.withAlphaComponent(0.3), range: lineRange)
            // Removes the highlight after 0.5 seconds to avoid visual clutter.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                textView.textStorage?.removeAttribute(.backgroundColor, range: lineRange)
            }
        }

        // Increases the font size in response to a notification (Cmd++).
        @objc func increaseFontSize() {
            // Caps the font size at 24 points to prevent excessive scaling.
            parent.fontSize = min(parent.fontSize + 2, 24)
        }

        // Decreases the font size in response to a notification (Cmd+-).
        @objc func decreaseFontSize() {
            // Ensures the font size doesn’t go below 10 points for readability.
            parent.fontSize = max(parent.fontSize - 2, 10)
        }

        // Updates syntax highlighting when the theme changes.
        @objc func themeChanged() {
            // Reapplies highlighting if the text view is available.
            if let textView = parent.textView {
                applySyntaxHighlighting(to: textView)
            }
        }

        // Shows the native find bar in response to a notification (Cmd+F or Cmd+R).
        @objc func showFindBar() {
            // Triggers the find bar if the text view is available.
            if let textView = parent.textView {
                textView.performFindPanelAction(nil)
            }
        }

        // Cleans up notification observers when the coordinator is deallocated.
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }

    // Convenience property to access the NSTextView from the current window.
    var textView: NSTextView? {
        // Navigates the view hierarchy to find the NSTextView within the NSScrollView.
        return (NSApp.keyWindow?.contentView?.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView)?.documentView as? NSTextView
    }
}

// A custom NSRulerView that displays line numbers in a gutter and handles clicks to jump to lines.
class LineNumberRulerView: NSRulerView {
    // Weak reference to the associated NSTextView to avoid retain cycles.
    weak var textView: NSTextView?
    // Closure to handle line number clicks, passing the clicked line number.
    var onLineClick: ((Int) -> Void)?

    // Initializes the ruler view with the text view and click handler.
    init(textView: NSTextView, onLineClick: @escaping (Int) -> Void) {
        self.textView = textView
        self.onLineClick = onLineClick
        // Initializes the ruler view as a vertical ruler attached to the text view’s scroll view
