import Foundation

struct Linter {
    static func lint(text: String, language: String) -> [String] {
        var errors: [String] = []
        switch language {
        case "swift":
            // Check for missing semicolons after statements (simplified)
            let lines = text.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                if line.trimmingCharacters(in: .whitespaces).hasSuffix(")") || line.contains("let ") || line.contains("var ") {
                    if !line.hasSuffix(";") && !line.isEmpty && !line.hasPrefix("//") {
                        errors.append("Line \(index + 1): Missing semicolon")
                    }
                }
            }
        case "python":
            // Check for incorrect indentation (simplified)
            let lines = text.components(separatedBy: .newlines)
            var indentLevel = 0
            for (index, line) in lines.enumerated() {
                let leadingSpaces = line.prefix(while: { $0 == " " }).count
                if line.contains(":") && !line.hasPrefix("#") {
                    indentLevel += 4
                } else if leadingSpaces != indentLevel && !line.isEmpty && !line.hasPrefix("#") {
                    errors.append("Line \(index + 1): Incorrect indentation (expected \(indentLevel) spaces)")
                }
            }
        case "bash":
            // Check for unclosed quotes
            let quotePattern = "\"[^\"]*$|'[^']*$"
            if let regex = try? NSRegularExpression(pattern: quotePattern, options: []) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    errors.append("Unclosed quote detected")
                }
            }
        case "markdown":
            // Check for invalid headers
            let headerPattern = "^#{1,6}\\s*[^\\s].*$"
            let lines = text.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                if line.hasPrefix("#") && !line.matches(headerPattern) {
                    errors.append("Line \(index + 1): Invalid Markdown header")
                }
            }
        default:
            break
        }
        return errors
    }
}

extension String {
    func matches(_ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return false }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
