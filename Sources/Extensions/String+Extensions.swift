import Foundation

extension String {
    var rangeOfLineNumber: NSRange? {
        let regex = try? NSRegularExpression(pattern: "Line (\\d+):", options: [])
        let range = NSRange(location: 0, length: self.utf16.count)
        if let match = regex?.firstMatch(in: self, options: [], range: range),
           let lineRange = Range(match.range(at: 1), in: self),
           let lineNumber = Int(self[lineRange]) {
            return NSRange(location: lineNumber - 1, length: 1)
        }
        return nil
    }

    func matches(_ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return false }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }

    func lineRange(for line: Int) -> NSRange {
        let lines = components(separatedBy: .newlines)
        guard line >= 0 && line < lines.count else { return NSRange(location: 0, length: 0) }
        let start = lines[0..<line].joined(separator: "\n").count + (line > 0 ? 1 : 0)
        return NSRange(location: start, length: lines[line].count)
    }
}