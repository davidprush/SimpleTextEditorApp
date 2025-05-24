import Foundation

struct FileTypeDetector {
    static func detectLanguage(from content: String, fileExtension: String?) -> String {
        if content.hasPrefix("#!/bin/bash") || content.hasPrefix("#!/bin/sh") {
            return "bash"
        } else if content.contains("import Swift") || content.contains("func ") {
            return "swift"
        } else if content.contains("import ") && fileExtension == "py" {
            return "python"
        } else if fileExtension == "md" {
            return "markdown"
        }
        return "plain"
    }
}