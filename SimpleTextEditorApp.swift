import SwiftUI

@main
struct SimpleTextEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
