/* 
    AUTHOR: David P. Rush 
    COPYRIGHT: 2025 MIT 
    DATE: 20250524
    PURPOSE: Implements a simple linter for Swift, Python, Bash, and Markdown, using regex-based rules
    to detect common errors. Designed to be lightweight and extensible.
*/

import Foundation

// Provides basic rule-based linting for supported languages, identifying common syntax errors.
struct Linter {
    // Lints the given text based on the specified language, returning error messages.
    static func lint(text: String, language: String) -> [String] {
        var errors: [String] = []
        switch language {
        case "swift":
            // Checks for missing semicolons after statements (simplified rule for demonstration).
            let lines = text.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                // Looks for lines that likely need a semicolon (e.g., function calls, variable declarations).
                if line.trimmingCharacters(in: .whitespaces).hasSuffix(")") || line.contains("let ") || line.contains("var ") {
                    if !line.hasSuffix(";") && !line.isEmpty && !line.hasPrefix("//") {
                        // Adds an error if a semicolon is missing.
                        errors.append("Line \(index + 1): Missing semicolon")
                    }
                }
            }
        case "python":
            // Checks for incorrect indentation (simplified rule).
            let lines = text.components(separatedBy: .newlines)
            var indentLevel = 0
            for (index, line) in lines.enumerated() {
                // Counts leading spaces to determine indentation.
                let leadingSpaces = line.prefix(while: { $0 == " " }).count
                // Increases expected indentation after a colon (e.g., if, def).
                if line.contains(":") && !line.hasPrefix("#") {
                    indentLevel += 4
                } else if leadingSpaces != indentLevel && !line.isEmpty && !line.hasPrefix("#") {
                    // Adds an error if indentation doesn’t match the expected level.
                    errors.append("Line \(index + 1): Incorrect indentation (expected \(indentLevel) spaces)")
                }
            }
        case "bash":
            // Checks for unclosed quotes in shell scripts.
            let quotePattern = "\"[^\"]*$|'[^']*$"
            if let regex = try? NSRegularExpression(pattern: quotePattern, options: []) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    // Adds an error if an unclosed quote is found.
                    errors.append("Unclosed quote detected")
                }
            }
        case "markdown":
            // Checks for invalid Markdown headers (e.g., missing space after #).
            let headerPattern = "^#{1,6}\\s*[^\\s].*$"
            let lines = text.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                if line.hasPrefix("#") && !line.matches(headerPattern) {
                    // Adds an error if a header is malformed.
                    errors.append("Line \(index + 1): Invalid Markdown header")
                }
            }
        default:
            // No linting for unsupported languages.
            break
        }
        return errors
    }
}

// Extension to add regex matching functionality to String.
extension String {
    // Checks if the string matches the given regex pattern.
    func matches(_ pattern: String) -> Bool {
        // Creates a regex with the specified pattern.
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return false }
        let range = NSRange(location: 0, length: self.utf16.count)
        // Returns true if the regex matches anywhere in the string.
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
