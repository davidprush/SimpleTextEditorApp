# Architecture
The SimpleTextEditor uses a SwiftUI-based UI with AppKit for advanced text editing. Key components:
- **TextDocument**: FileDocument model for file handling.
- **CodeTextView**: NSTextView wrapper for editing.
- **CloudSyncManager**: Manages iCloud sync.