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

