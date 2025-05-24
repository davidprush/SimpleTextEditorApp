# SimpleTextEditorApp
SimpleTextEditorApp (STEA), a basic text editor as a native macOS app using Swift and SwiftUI, includes standard macOS app functionalities like file handling, menu bar integration, and basic text editing features.

A native macOS text editor using Swift, incorporating both SwiftUI for the modern user interface and AppKit for advanced text editing capabilities. The application will feature standard macOS functionalities—such as file handling, a menu bar, and basic text editing—and include enhancements like Markdown preview, autosave, custom menus, syntax highlighting, line numbers, and export options. 

A native macOS app should support opening, editing, and saving text files, with a standard menu bar including File, Edit, Window, and Help options. SwiftUI is ideal for the interface, and since it’s a document-based app, DocumentGroup will handle file operations seamlessly.

## Key Components

1. `SimpleTextEditorApp.swift`: The main app entry point, defining the document-based scene. Uses `DocumentGroup` to create a document-based app, initializing new documents with `TextDocument` and displaying them in `ContentView`.

2. `TextDocument.swift`: A struct conforming to `FileDocument` to manage text content and file I/O. Conforms to `FileDocument`, supporting plain text files (`UTType.plainText`). It reads from and writes to files using UTF-8 encoding.

3. `ContentView.swift`: The primary view containing a `TextEditor` for text input. Features a `TextEditor` bound to the document’s text, with a minimum window size and a toolbar showing the character count.

## Text Editor Enhancements

To make the app more powerful and align with macOS conventions, added the following enhancements:

- Markdown Preview: Display rendered Markdown for `.md` files.

- Autosave: Periodically save changes with a user toggle.

- Custom Menus: Add a "Text" menu for find, replace, and font adjustments.

- Syntax Highlighting: Use `Highlightr` with `NSTextView` for code highlighting.

- Line Numbers: Implement a gutter with line numbers.

- Export Options: Support exporting to HTML, PDF, Markdown, and RTF.

- Native Find Bar: Leverage `NSTextView`’s built-in find functionality.

- Custom Themes: Allow theme selection for syntax highlighting.

- Performance Optimization: Debounce highlighting for large documents.

