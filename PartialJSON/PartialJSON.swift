//
//  PartialJSON.swift
//  PartialJSON
//
//  Created by Ivan Trufanov on 16/09/2025.
//

import Foundation

/// A Swift library for parsing incomplete/streaming JSON data.
///
/// This library allows you to parse JSON strings that may be incomplete,
/// which is particularly useful for:
/// - Streaming JSON responses
/// - Real-time data processing
/// - Progressive JSON parsing
/// - Handling truncated JSON from APIs or logs

/// Error thrown when JSON is incomplete and the incompleteness is not allowed by the parsing options.
///
/// This error indicates that the JSON string ended unexpectedly in a place where
/// the current parsing options don't allow partial parsing.
///
/// ## Example
/// ```swift
/// // This throws PartialJSONError because numbers aren't allowed to be partial by default
/// let result = try parseJSON("[1, 2, 3.", options: .allExceptNumbers)
/// ```
public struct PartialJSONError: Error, CustomStringConvertible {
    /// The error message describing what was expected
    public let message: String
    
    /// The character position in the input string where the error occurred
    public let position: Int
    
    /// Creates a new PartialJSONError
    /// - Parameters:
    ///   - message: Description of what was expected
    ///   - position: Character position where the error occurred
    public init(_ message: String, at position: Int) {
        self.message = message
        self.position = position
    }
    
    public var description: String {
        return "\(message) at position \(position)"
    }
}

/// Error thrown when JSON is malformed and cannot be parsed.
///
/// This error indicates that the JSON string contains invalid syntax that
/// cannot be parsed regardless of the parsing options.
///
/// ## Example
/// ```swift
/// // This throws MalformedJSONError because of invalid syntax
/// let result = try parseJSON("{invalid json}")
/// ```
public struct MalformedJSONError: Error, CustomStringConvertible {
    /// The error message describing what's wrong with the JSON
    public let message: String
    
    /// The character position in the input string where the error occurred
    public let position: Int
    
    /// Creates a new MalformedJSONError
    /// - Parameters:
    ///   - message: Description of the malformation
    ///   - position: Character position where the error occurred
    public init(_ message: String, at position: Int) {
        self.message = message
        self.position = position
    }
    
    public var description: String {
        return "\(message) at position \(position)"
    }
}

/// Parses a potentially incomplete JSON string.
///
/// This function attempts to parse a JSON string that may be incomplete or truncated.
/// It first tries to parse the string as complete JSON, and if that fails, it attempts
/// partial parsing according to the specified options.
///
/// ## Examples
///
/// ```swift
/// // Parse a truncated array
/// let result = try parseJSON("[1, 2, 3")
/// // Returns: [1, 2, 3]
///
/// // Parse a truncated object
/// let result = try parseJSON("{\"name\": \"John\", \"age\"")
/// // Returns: ["name": "John"]
///
/// // Parse with custom options
/// let result = try parseJSON("[1, 2, 3.", options: .all)
/// // Returns: [1, 2, 3.0] (allows partial numbers)
/// ```
///
/// - Parameters:
///   - jsonString: The JSON string to parse, which may be incomplete
///   - options: Controls which types can be partially parsed (default: `.allExceptNumbers`)
/// - Returns: The parsed JSON as `Any` (could be Dictionary, Array, String, Number, Bool, or NSNull)
/// - Throws: 
///   - `PartialJSONError` if the JSON is incomplete in a way not allowed by options
///   - `MalformedJSONError` if the JSON contains invalid syntax
public func parseJSON(_ jsonString: String, options: PartialJSONOptions = .allExceptNumbers) throws -> Any {
    guard !jsonString.isEmpty else {
        throw MalformedJSONError("Empty string", at: 0)
    }
    
    let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        throw MalformedJSONError("Empty string after trimming", at: 0)
    }
    
    // Try to parse as complete JSON first
    do {
        guard let data = trimmed.data(using: .utf8) else {
            throw MalformedJSONError("Invalid UTF-8 encoding", at: 0)
        }
        return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    } catch {
        // If complete parsing fails, try partial parsing
        return try parsePartialJSON(trimmed, options: options)
    }
}

// MARK: - Private Parsing Implementation

private func parsePartialJSON(_ jsonString: String, options: PartialJSONOptions) throws -> Any {
    var currentIndex = jsonString.startIndex
    let endIndex = jsonString.endIndex
    
    /// Skips whitespace characters from the current position
    func skipWhitespace() {
        while currentIndex < endIndex && jsonString[currentIndex].isWhitespace {
            currentIndex = jsonString.index(after: currentIndex)
        }
    }
    
    /// Throws a PartialJSONError at the current position
    func markPartialJSON(_ message: String) throws {
        let position = jsonString.distance(from: jsonString.startIndex, to: currentIndex)
        throw PartialJSONError(message, at: position)
    }
    
    /// Throws a MalformedJSONError at the current position
    func throwMalformedError(_ message: String) throws {
        let position = jsonString.distance(from: jsonString.startIndex, to: currentIndex)
        throw MalformedJSONError(message, at: position)
    }
    
    /// Tries to match a string at the current position
    /// - Returns: The index after the match if successful, nil otherwise
    func tryMatch(_ string: String) -> String.Index? {
        let matchEndIndex = jsonString.index(currentIndex, offsetBy: string.count, limitedBy: endIndex)
        guard let endIdx = matchEndIndex else { return nil }
        
        let range = currentIndex..<endIdx
        if jsonString[range] == string {
            return endIdx
        }
        return nil
    }
    
    /// Tries to partially match a string at the current position
    /// - Returns: true if the remaining string is a prefix of the target string
    func tryPartialMatch(_ target: String) -> Bool {
        let remaining = String(jsonString[currentIndex...])
        if target.hasPrefix(remaining) && !remaining.isEmpty {
            currentIndex = endIndex
            return true
        }
        return false
    }
    
    /// Parses any JSON value from the current position
    func parseAny() throws -> Any {
        skipWhitespace()
        if currentIndex >= endIndex {
            try markPartialJSON("Unexpected end of input")
        }
        
        let currentChar = jsonString[currentIndex]
        
        if currentChar == "\"" {
            return try parseString()
        }
        if currentChar == "{" {
            return try parseObject()
        }
        if currentChar == "[" {
            return try parseArray()
        }
        
        // Check for null
        if let match = tryMatch("null") {
            currentIndex = match
            return NSNull()
        }
        if options.contains(.null) && tryPartialMatch("null") {
            return NSNull()
        }
        
        // Check for true
        if let match = tryMatch("true") {
            currentIndex = match
            return true
        }
        if options.contains(.boolean) && tryPartialMatch("true") {
            return true
        }
        
        // Check for false
        if let match = tryMatch("false") {
            currentIndex = match
            return false
        }
        if options.contains(.boolean) && tryPartialMatch("false") {
            return false
        }
        
        // Check for Infinity
        if let match = tryMatch("Infinity") {
            currentIndex = match
            return Double.infinity
        }
        if options.contains(.infinity) && tryPartialMatch("Infinity") {
            return Double.infinity
        }
        
        // Check for -Infinity
        if let match = tryMatch("-Infinity") {
            currentIndex = match
            return -Double.infinity
        }
        if options.contains(.negativeInfinity) && tryPartialMatch("-Infinity") {
            return -Double.infinity
        }
        
        // Check for NaN
        if let match = tryMatch("NaN") {
            currentIndex = match
            return Double.nan
        }
        if options.contains(.nan) && tryPartialMatch("NaN") {
            return Double.nan
        }
        
        return try parseNumber()
    }
    
    /// Parses a JSON string value
    func parseString() throws -> String {
        let startIndex = currentIndex
        var escape = false
        currentIndex = jsonString.index(after: currentIndex) // skip initial quote
        
        while currentIndex < endIndex {
            let char = jsonString[currentIndex]
            if char == "\"" && !escape {
                break
            }
            escape = (char == "\\") ? !escape : false
            currentIndex = jsonString.index(after: currentIndex)
        }
        
        if currentIndex < endIndex && jsonString[currentIndex] == "\"" {
            let stringEndIndex = currentIndex
            currentIndex = jsonString.index(after: currentIndex) // skip final quote
            
            let stringContent = String(jsonString[startIndex...stringEndIndex])
            
            guard let data = stringContent.data(using: .utf8) else {
                try throwMalformedError("Invalid UTF-8 encoding")
                return ""
            }
            
            do {
                let result = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
                return result as? String ?? ""
            } catch {
                try throwMalformedError(String(describing: error))
            }
        } else if options.contains(.string) {
            let stringContent = String(jsonString[startIndex..<currentIndex]) + "\""
            
            guard let data = stringContent.data(using: .utf8) else {
                try throwMalformedError("Invalid UTF-8 encoding")
                return ""
            }
            
            do {
                let result = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
                return result as? String ?? ""
            } catch {
                // Try to find the last valid escape sequence
                if let lastBackslash = stringContent.lastIndex(of: "\\") {
                    let truncatedContent = String(stringContent[..<lastBackslash]) + "\""
                    guard let truncatedData = truncatedContent.data(using: .utf8) else {
                        try throwMalformedError("Invalid UTF-8 encoding")
                        return ""
                    }
                    do {
                        let result = try JSONSerialization.jsonObject(with: truncatedData, options: [.fragmentsAllowed])
                        return result as? String ?? ""
                    } catch {
                        try throwMalformedError("Invalid escape sequence")
                    }
                } else {
                    try throwMalformedError("Invalid escape sequence")
                }
            }
        }
        
        try markPartialJSON("Unterminated string literal")
        return ""
    }
    
    /// Parses a JSON object
    func parseObject() throws -> [String: Any] {
        currentIndex = jsonString.index(after: currentIndex) // skip initial brace
        skipWhitespace()
        var obj: [String: Any] = [:]
        
        do {
            while currentIndex < endIndex && jsonString[currentIndex] != "}" {
                skipWhitespace()
                if currentIndex >= endIndex && options.contains(.object) {
                    return obj
                }
                
                let key = try parseString()
                skipWhitespace()
                
                if currentIndex >= endIndex {
                    if options.contains(.object) {
                        return obj
                    } else {
                        try markPartialJSON("Expected ':' after key")
                    }
                }
                
                if jsonString[currentIndex] != ":" {
                    if options.contains(.object) {
                        return obj
                    } else {
                        try markPartialJSON("Expected ':' after key")
                    }
                }
                
                currentIndex = jsonString.index(after: currentIndex) // skip colon
                
                do {
                    let value = try parseAny()
                    obj[key] = value
                } catch {
                    if options.contains(.object) {
                        return obj
                    } else {
                        throw error
                    }
                }
                
                skipWhitespace()
                if currentIndex < endIndex && jsonString[currentIndex] == "," {
                    currentIndex = jsonString.index(after: currentIndex) // skip comma
                }
            }
        } catch {
            if options.contains(.object) {
                return obj
            } else {
                try markPartialJSON("Expected '}' at end of object")
            }
        }
        
        if currentIndex < endIndex && jsonString[currentIndex] == "}" {
            currentIndex = jsonString.index(after: currentIndex) // skip final brace
        }
        
        return obj
    }
    
    /// Parses a JSON array
    func parseArray() throws -> [Any] {
        currentIndex = jsonString.index(after: currentIndex) // skip initial bracket
        var arr: [Any] = []
        var isLastItemOmitted = false
        
        do {
            while currentIndex < endIndex && jsonString[currentIndex] != "]" {
                do {
                    isLastItemOmitted = false
                    let value = try parseAny()
                    arr.append(value)
                } catch {
                    // If individual element parsing fails and arrays are allowed to be partial,
                    // skip this element and continue parsing
                    if options.contains(.array) {
                        // Skip to the next comma or end of array
                        while currentIndex < endIndex && 
                              jsonString[currentIndex] != "," &&
                              jsonString[currentIndex] != "]" {
                            currentIndex = jsonString.index(after: currentIndex)
                        }
                        if currentIndex < endIndex && jsonString[currentIndex] == "," {
                            currentIndex = jsonString.index(after: currentIndex) // skip comma
                        }
                        
                        isLastItemOmitted = true
                        continue
                    } else {
                        throw error
                    }
                }
                skipWhitespace()
                
                if currentIndex < endIndex && jsonString[currentIndex] == "," {
                    currentIndex = jsonString.index(after: currentIndex) // skip comma
                }
            }
        } catch {
            if options.contains(.array) {
                return arr
            }
            try markPartialJSON("Expected ']' at end of array")
        }
        
        if currentIndex < endIndex && jsonString[currentIndex] == "]" {
            currentIndex = jsonString.index(after: currentIndex) // skip final bracket
        }
        
        if isLastItemOmitted == false, let lastItem = arr.last, 
           (lastItem is Int || lastItem is Double || lastItem is Float), !options.contains(.number) {
            // if last item is number - it could be incomplete, check options
            _ = arr.popLast()
        }
        
        return arr
    }
    
    /// Parses a JSON number
    func parseNumber() throws -> Any {
        let startIndex = currentIndex
        var hasDecimal = false
        var hasExponent = false
        
        // Handle negative sign
        if currentIndex < endIndex && jsonString[currentIndex] == "-" {
            currentIndex = jsonString.index(after: currentIndex)
        }
        
        // Handle digits before decimal point
        while currentIndex < endIndex && jsonString[currentIndex].isNumber {
            currentIndex = jsonString.index(after: currentIndex)
        }
        
        // Handle decimal point
        if currentIndex < endIndex && jsonString[currentIndex] == "." {
            hasDecimal = true
            currentIndex = jsonString.index(after: currentIndex)
            
            // Handle digits after decimal point
            while currentIndex < endIndex && jsonString[currentIndex].isNumber {
                currentIndex = jsonString.index(after: currentIndex)
            }
        }
        
        // Handle exponent
        if currentIndex < endIndex && (jsonString[currentIndex] == "e" || jsonString[currentIndex] == "E") {
            hasExponent = true
            currentIndex = jsonString.index(after: currentIndex)
            
            // Handle exponent sign
            if currentIndex < endIndex && (jsonString[currentIndex] == "+" || jsonString[currentIndex] == "-") {
                currentIndex = jsonString.index(after: currentIndex)
            }
            
            // Handle exponent digits
            while currentIndex < endIndex && jsonString[currentIndex].isNumber {
                currentIndex = jsonString.index(after: currentIndex)
            }
        }
        
        let numberString = String(jsonString[startIndex..<currentIndex])
        
        // Check if the number string represents an incomplete number
        let isIncomplete = (hasDecimal && !hasExponent && (currentIndex >= endIndex || !jsonString[currentIndex].isNumber)) ||
                          (hasExponent && (currentIndex >= endIndex || !jsonString[currentIndex].isNumber))
        
        // If it's incomplete and partial numbers are not allowed, throw an error
        if isIncomplete && !options.contains(.number) {
            try throwMalformedError("Invalid number")
        }
        
        // Check if we have a valid number
        if let number = Double(numberString) {
            // Return as Int if it's a whole number and fits in Int range
            if !hasDecimal && !hasExponent && number >= Double(Int.min) && number <= Double(Int.max) && number.truncatingRemainder(dividingBy: 1) == 0 {
                return Int(number)
            }
            return number
        }
        
        // If we can't parse as a complete number, check if partial numbers are allowed
        if options.contains(.number) {
            // Try to parse what we have so far
            if let partialNumber = Double(numberString) {
                return partialNumber
            }
            
            // If we have at least one digit, try to parse as much as possible
            if !numberString.isEmpty && numberString.first?.isNumber == true {
                // Find the longest valid number prefix
                for i in (1...numberString.count).reversed() {
                    let prefix = String(numberString.prefix(i))
                    if let number = Double(prefix) {
                        return number
                    }
                }
            }
        }
        
        try throwMalformedError("Invalid number")
        return 0
    }
    
    return try parseAny()
}

/// Convenience function for parsing potentially incomplete JSON.
///
/// This is an alias for `parseJSON(_:options:)` with a shorter name.
///
/// ## Example
/// ```swift
/// let result = try parse("{\"incomplete\": tr")
/// // Returns: ["incomplete": true]
/// ```
///
/// - Parameters:
///   - jsonString: The JSON string to parse, which may be incomplete
///   - options: Controls which types can be partially parsed (default: `.allExceptNumbers`)
/// - Returns: The parsed JSON as `Any`
/// - Throws: 
///   - `PartialJSONError` if the JSON is incomplete in a way not allowed by options
///   - `MalformedJSONError` if the JSON contains invalid syntax
public func parse(_ jsonString: String, options: PartialJSONOptions = .allExceptNumbers) throws -> Any {
    return try parseJSON(jsonString, options: options)
}
