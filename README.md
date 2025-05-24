# SimpleTextEditorApp
SimpleTextEditorApp (STEA), a basic text editor as a native macOS app using Swift and SwiftUI, includes standard macOS app functionalities like file handling, menu bar integration, and basic text editing features.

A native macOS text editor using Swift, incorporating both SwiftUI for the modern user interface and AppKit for advanced text editing capabilities. The application will feature standard macOS functionalities—such as file handling, a menu bar, and basic text editing—and include enhancements like Markdown preview, autosave, custom menus, syntax highlighting, line numbers, and export options. 

A native macOS app should support opening, editing, and saving text files, with a standard menu bar including File, Edit, Window, and Help options. SwiftUI is ideal for the interface, and since it’s a document-based app, DocumentGroup will handle file operations seamlessly.

## Key Components

1. `SimpleTextEditorApp.swift`: The main app entry point, defining the document-based scene.

2. `TextDocument.swift`: A struct conforming to `FileDocument` to manage text content and file I/O.

3. `ContentView.swift`: The primary view containing a `TextEditor` for text input.


