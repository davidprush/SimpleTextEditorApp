import SwiftUI
import AppKit
import Highlightr

struct CodeTextView: NSViewRepresentable {
    @Binding var text: String
    let language: String
    var undoManager: UndoManager?
    @State private var fontSize: CGFloat = 14
    @State private var highlightWorkItem: DispatchWorkItem?

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.delegate = context.coordinator
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        context.coordinator.applySyntaxHighlighting(to: textView)

        let gutterView = LineNumberRulerView(textView: textView)
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.verticalRulerView = gutterView
        scrollView.rulersVisible = true

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.increaseFontSize), name: .NSIncreaseFontSize, object: nil)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.decreaseFontSize), name: .NSDecreaseFontSize, object: nil)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.themeChanged), name: .NSThemeChanged, object: nil)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.showFindBar), name: .NSFindPanelAction, object: nil)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.showFindBar), name: .NSReplacePanelAction, object: nil)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            if textView.string != text {
                textView.string = text
            }
            textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            context.coordinator.applySyntaxHighlighting(to: textView)
            if let gutterView = nsView.verticalRulerView as? LineNumberRulerView {
                gutterView.updateLineNumbers()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeTextView
        var highlighter: Highlightr?

        init(_ parent: CodeTextView) {
            self.parent = parent
            self.highlighter = Highlightr()
            super.init()
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
                debounceHighlighting(for: textView)
                parent.undoManager?.registerUndo(withTarget: textView) { tv in
                    tv.string = parent.text
                }
                if let scrollView = textView.enclosingScrollView,
                   let gutterView = scrollView.verticalRulerView as? LineNumberRulerView {
                    gutterView.updateLineNumbers()
                }
            }
        }

        func debounceHighlighting(for textView: NSTextView) {
            parent.highlightWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.applySyntaxHighlighting(to: textView)
            }
            parent.highlightWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }

        func applySyntaxHighlighting(to textView: NSTextView) {
            guard let highlighter = highlighter else { return }
            highlighter.setTheme(to: TextDocument.highlightrTheme)
            if let attributedString = highlighter.highlight(textView.string, as: parent.language) {
                let currentSelection = textView.selectedRanges
                textView.textStorage?.setAttributedString(attributedString)
                textView.setSelectedRanges(currentSelection)
            }
        }

        @objc func increaseFontSize() { parent.fontSize = min(parent.fontSize + 2, 24) }
        @objc func decreaseFontSize() { parent.fontSize = max(parent.fontSize - 2, 10) }
        @objc func themeChanged() { if let textView = parent.textView { applySyntaxHighlighting(to: textView) } }
        @objc func showFindBar() { if let textView = parent.textView { textView.performFindPanelAction(nil) } }

        deinit { NotificationCenter.default.removeObserver(self) }
    }

    var textView: NSTextView? {
        return (NSApp.keyWindow?.contentView?.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView)?.documentView as? NSTextView
    }
}

class LineNumberRulerView: NSRulerView {
    weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateLineNumbers() {
        guard let textView = textView else { return }
        setNeedsDisplay(bounds)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let textView = textView, let layoutManager = textView.layoutManager, let textContainer = textView.textContainer else { return }

        NSGraphicsContext.saveGraphicsState()
        let text = textView.string
        let lines = text.components(separatedBy: .newlines)
        let font = NSFont.systemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.gray]

        let glyphRange = layoutManager.glyphRange(for: textContainer)
        var point = NSPoint(x: 10, y: 0)

        for i in 0..<lines.count {
            let lineRange = (text as NSString).lineRange(for: NSRange(location: text.utf16.count > 0 ? text.lineRange(for: i).location : 0, length: 0))
            let glyphRect = layoutManager.boundingRect(forGlyphRange: layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil), in: textContainer)
            point.y = glyphRect.origin.y
            let lineNumber = "\(i + 1)"
            lineNumber.draw(at: point, withAttributes: attributes)
            point.y += glyphRect.size.height
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}
