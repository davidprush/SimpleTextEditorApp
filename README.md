# SimpleTextEditorApp

> SimpleTextEditorApp (STEA), a basic text editor as a native macOS app using Swift and SwiftUI, includes standard macOS app functionalities like file handling, menu bar integration, and basic text editing features.

A native macOS text editor using Swift, incorporating both SwiftUI for the modern user interface and AppKit for advanced text editing capabilities. The application will feature standard macOS functionalities—such as file handling, a menu bar, and basic text editing—and include enhancements like Markdown preview, autosave, custom menus, syntax highlighting, line numbers, and export options. 

*A native macOS app should support opening, editing, and saving text files, with a standard menu bar including File, Edit, Window, and Help options. SwiftUI is ideal for the interface, and since it’s a document-based app, DocumentGroup will handle file operations seamlessly.*

> **Core Features:** Document-based file handling, syntax highlighting (Highlightr), Markdown preview, autosave, custom menus, native find bar, line numbers, and export options (HTML, PDF, Markdown, RTF).

## Key Components

1. `SimpleTextEditorApp.swift`: The main app entry point, defining the document-based scene. Uses `DocumentGroup` to create a document-based app, initializing new documents with `TextDocument` and displaying them in `ContentView`.

2. `TextDocument.swift`: A struct conforming to `FileDocument` to manage text content and file I/O. Conforms to `FileDocument`, supporting plain text files (`UTType.plainText`). It reads from and writes to files using UTF-8 encoding.

3. `ContentView.swift`: The primary view containing a `TextEditor` for text input. Features a `TextEditor` bound to the document’s text, with a minimum window size and a toolbar showing the character count.

## This text editor offers:

- Document-Based Architecture: Supports plain text, Markdown, Swift, Python, and shell scripts.

- Syntax Highlighting: Powered by Highlightr with customizable themes.

- Markdown Preview: Renders Markdown in a split view.

- Autosave: Saves changes every 5 seconds, toggled in settings.

- Custom Menus: Includes "Text" and "Export" options with shortcuts.

- Native Find Bar: Built into `NSTextView`.

- Line Numbers: Displayed in a gutter.

- Export Options: HTML, PDF, Markdown, and RTF formats.

- Performance: Debounced highlighting for efficiency.

## Dependencies

To run this code, add the following via Swift Package Manager:

- `Highlightr`: https://github.com/raspu/Highlightr.git (for syntax highlighting).

- `Down`: https://github.com/johnxnguyen/Down.git (for Markdown rendering).

## File Structure & Explanations

### `info.plist`

- Ensure support for `.txt`, `.md`, `.sh`, `.swift`, `.py`

- Add iCloud capabilities

- Enable App Sandbox with User Selected File (Read/Write) and iCloud capabilities in Xcode

### `SimpleTextEditorApp.swift`

- Customizes the menu bar with File commands and adds "Text" and "Export" menus.

- Uses notifications to trigger actions in `ContentView`.

- Includes a `Settings` scene for user preferences.

- Added a `CloudSyncManager` as a `@StateObject` to handle iCloud synchronization, passed to `ContentView` and `SettingsView` via `environmentObject`

### `TextDocument.swift`

- Supports multiple file types and detects the language for syntax highlighting.

- Stores autosave and theme settings in `UserDefaults`.

- Added `iCloudSyncKey` for enabling/disabling iCloud sync.

- Synced `autosaveEnabled`, `highlightrTheme`, and `iCloudSyncEnabled` with `NSUbiquitousKeyValueStore` for iCloud persistence.

### `CloudSyncManager.swift`

- Manages iCloud synchronization for documents and settings.

- Uses `NSMetadataQuery` to monitor iCloud Drive for supported file types.

- Syncs settings (autosave, theme, iCloud sync) via `NSUbiquitousKeyValueStore`.

### `ContentView.swift`

- Uses `CodeTextView` (below) for editing with syntax highlighting.

- Shows a Markdown preview toggle for `.md` files using the `Down` library.

- Implements autosave with a 5-second timer, configurable via settings.

- Provides export functions using `NSSavePanel` and AppKit utilities.

- Added `lintErrors` state to display linting issues in the toolbar.

- Calls `Linter.lint` on text changes to perform syntax checking.

- Wraps `NSTextView` for syntax highlighting (via `Highlightr`), line numbers, and a native find bar.

- Debounces highlighting updates to optimize performance.

- Supports font size adjustments and theme changes via notifications.

### `Linter.swift`

- Provides basic linting rules for Swift (semicolons), Python (indentation), Bash (quotes), and Markdown (headers).

- Returns error messages with line numbers for display in the UI.

### `SettingsView.swift`

- Provides a settings panel to toggle autosave and select `Highlightr` themes.

- Updates the editor’s appearance when the theme changes.

- Added `iCloudSyncEnabled` toggle, disabled if iCloud is unavailable.

- Included `ThemePreviewView` to show a sample Swift code snippet with the selected Highlightr theme.

## Current Testing and Running

### Setup:

1. Add Highlightr and Down via Swift Package Manager.

2. Configure iCloud capabilities in Xcode (entitlements and `Info.plist`).

3. Ensure the app sandbox allows file read/write and iCloud access.

### Proposed Test Cases:

- **Theme Preview:** Open the Settings window (Cmd+,), select different themes, and verify the preview updates.

- **Clickable Line Numbers:** Click line numbers in the gutter, confirm the cursor jumps to the correct line with a brief highlight.

- **Syntax Checking:** Create files with intentional errors (e.g., missing semicolon in Swift, incorrect indentation in Python), verify errors appear in the toolbar and lines are underlined.

- **Cloud Sync:** Enable iCloud sync, save a document, and check if it appears in iCloud Drive on another device. Change settings and verify they sync.

- **Existing Features:** Confirm Markdown preview, autosave, native find bar, export options (HTML, PDF, Markdown, RTF), and syntax highlighting work as expected.
