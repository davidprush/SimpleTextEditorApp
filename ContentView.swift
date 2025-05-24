import SwiftUI

struct ContentView: View {
    @Binding var document: TextDocument

    var body: some View {
        TextEditor(text: $document.text)
            .frame(minWidth: 400, minHeight: 300)
            .toolbar {
                ToolbarItem(placement: .status) {
                    Text("\(document.text.count) characters")
                }
            }
    }
}
