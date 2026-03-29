//
//  TextLoader.swift
//  OT main
//
//  Created by user@54 on 27/11/25.
//

// TextLoader.swift
import Foundation

/// Load a .txt file from the main bundle. Pass the resource name WITHOUT the extension.
/// Example: `loadTextFile(named: "aboutus")`
func loadTextFile(named fileName: String) -> String {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "txt") else {
        return "Content unavailable: file \(fileName).txt not found in bundle."
    }
    do {
        return try String(contentsOf: url, encoding: .utf8)
    } catch {
        return "Content unavailable: failed to read \(fileName).txt (\(error.localizedDescription))"
    }
}
