// swiftlint:disable no_print
import Foundation

// MARK: - Basic Examples

func basicExamples() {
    print("=== Basic Partial JSON Parsing Examples ===\n")
    
    // Example 1: Incomplete array
    do {
        let incompleteArray = "[1, 2, 3"
        let result = try parse(incompleteArray)
        print("Incomplete array: \(incompleteArray)")
        print("Parsed result: \(result)\n")
    } catch {
        print("Error: \(error)\n")
    }
    
    // Example 2: Incomplete object
    do {
        let incompleteObject = "{\"name\": \"Alice\", \"age\": 30, \"city\""
        let result = try parse(incompleteObject)
        print("Incomplete object: \(incompleteObject)")
        print("Parsed result: \(result)\n")
    } catch {
        print("Error: \(error)\n")
    }
    
    // Example 3: Nested incomplete structures
    do {
        let nestedJSON = "{\"users\": [{\"id\": 1}, {\"id\": 2"
        let result = try parse(nestedJSON)
        print("Nested incomplete: \(nestedJSON)")
        print("Parsed result: \(result)\n")
    } catch {
        print("Error: \(error)\n")
    }
}

// MARK: - Streaming Example

class StreamingJSONParser {
    private var buffer = ""
    private let options: PartialJSONOptions
    
    init(options: PartialJSONOptions = .allExceptNumbers) {
        self.options = options
    }
    
    func append(_ chunk: String) -> (result: Any?, isComplete: Bool) {
        buffer += chunk
        
        do {
            let result = try parse(buffer, options: options)
            // Try to parse as complete JSON to verify it's actually complete
            if let data = buffer.data(using: .utf8),
               (try? JSONSerialization.jsonObject(with: data)) != nil {
                return (result, true)
            }
            return (result, false)
        } catch {
            return (nil, false)
        }
    }
    
    func reset() {
        buffer = ""
    }
}

func streamingExample() {
    print("=== Streaming JSON Parser Example ===\n")
    
    let parser = StreamingJSONParser(options: .all)
    let chunks = [
        "{\"status",
        "\": \"loading\",",
        " \"progress\": 0.",
        "75, \"items\": [",
        "\"item1\", \"item2\"",
        "]}"
    ]
    
    print("Streaming chunks:")
    for (index, chunk) in chunks.enumerated() {
        let (result, isComplete) = parser.append(chunk)
        print("Chunk \(index + 1): \"\(chunk)\"")
        if let result = result {
            print("  Current parse: \(result)")
            print("  Complete: \(isComplete)")
        } else {
            print("  Not yet parseable")
        }
    }
    print()
}

// MARK: - Options Example

func optionsExample() {
    print("=== Parsing Options Example ===\n")
    
    let partialNumber = "[1, 2, 3."
    
    // Without number option (default)
    do {
        let result = try parse(partialNumber, options: .allExceptNumbers)
        print("Without .number option: \(partialNumber)")
        print("Result: \(result)\n")
    } catch {
        print("Without .number option: \(partialNumber)")
        print("Error: \(error)\n")
    }
    
    // With number option
    do {
        let result = try parse(partialNumber, options: .all)
        print("With .number option: \(partialNumber)")
        print("Result: \(result)\n")
    } catch {
        print("Error: \(error)\n")
    }
    
    // Partial boolean
    do {
        let partialBool = "{\"active\": tr"
        let result = try parse(partialBool, options: .all)
        print("Partial boolean: \(partialBool)")
        print("Result: \(result)\n")
    } catch {
        print("Error: \(error)\n")
    }
}

// MARK: - Error Handling Example

func errorHandlingExample() {
    print("=== Error Handling Example ===\n")
    
    // Malformed JSON
    do {
        let malformed = "{invalid json}"
        _ = try parse(malformed)
    } catch let error as MalformedJSONError {
        print("Malformed JSON Error:")
        print("  Message: \(error.message)")
        print("  Position: \(error.position)\n")
    } catch {
        print("Unexpected error: \(error)\n")
    }
    
    // Partial not allowed
    do {
        let partial = "\"unclosed string"
        _ = try parse(partial, options: [])  // No partial types allowed
    } catch let error as PartialJSONError {
        print("Partial JSON Error:")
        print("  Message: \(error.message)")
        print("  Position: \(error.position)\n")
    } catch {
        print("Unexpected error: \(error)\n")
    }
}

// MARK: - Main

func runExamples() {
    basicExamples()
    streamingExample()
    optionsExample()
    errorHandlingExample()
}

// Uncomment to run examples
// runExamples()
