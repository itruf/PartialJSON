# PartialJSON

> **Attribution**: This library is developed based on the approach and methodology from [OpenAI's Node.js library](https://github.com/openai/openai-node), which itself vendors the [Promplate partial-json-parser-js](https://github.com/promplate/partial-json-parser-js) library. The test cases and parsing strategies are adapted from both the original @promplate implementation and @OpenAI's usage of it, ported to Swift with additional Swift-specific optimizations.
> 
> Special thanks to the @Promplate team for creating [the original partial JSON parsing solution](https://github.com/promplate/partial-json-parser-js) that inspired this Swift implementation.

A Swift library for parsing incomplete or streaming JSON data. Perfect for handling truncated JSON responses, streaming APIs, or progressive JSON parsing scenarios.

## Features

- ✅ Parse incomplete JSON strings that are truncated or still being streamed
- ✅ Configurable parsing options to control which types can be partial
- ✅ Support for all JSON types: objects, arrays, strings, numbers, booleans, and null
- ✅ Handle special numeric values: `Infinity`, `-Infinity`, and `NaN`
- ✅ Comprehensive error handling with detailed error messages
- ✅ Zero dependencies beyond Foundation
- ✅ Full test coverage
- ✅ Swift 6 compatible

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/itruf/PartialJSON.git", from: "0.0.2")
]
```

Then add `PartialJSON` as a dependency to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["PartialJSON"]
    )
]
```

### Xcode Project

1. In Xcode, select File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/itruf/PartialJSON.git`
3. Select your desired version and add to your project

## Usage

### Basic Usage

```swift
import PartialJSON

// Parse incomplete JSON with default options
let incompleteJSON = "[1, 2, 3"
let result = try PartialJSON.parse(incompleteJSON)
// Result: [1, 2, 3]

// Parse incomplete object
let partialObject = "{\"name\": \"John\", \"age\""
let obj = try PartialJSON.parse(partialObject)
// Result: ["name": "John"]
```

### Parsing Options

Control which types can be parsed when incomplete:

```swift
// Allow all types to be partial
let result = try PartialJSON.parse("[1, 2, 3.", options: .all)
// Result: [1, 2, 3.0]

// Allow only arrays and objects to be partial
let result = try PartialJSON.parse("[1, 2, 3", options: .collections)
// Result: [1, 2, 3]

// Custom options combination
let customOptions: PartialJSONOptions = [.array, .object, .string]
let result = try PartialJSON.parse("{\"text\": \"incompl", options: customOptions)
// Result: ["text": "incompl"]
```

### Available Options

```swift
// Individual options
.string           // Allow partial strings
.number           // Allow partial numbers
.array            // Allow partial arrays
.object           // Allow partial objects
.null             // Allow partial null (e.g., "nu" → null)
.boolean          // Allow partial booleans (e.g., "tr" → true)
.nan              // Allow partial NaN
.infinity         // Allow partial Infinity
.negativeInfinity // Allow partial -Infinity

// Convenience combinations
.allInfinity      // Both positive and negative infinity
.special          // null, boolean, infinity, nan
.atomic           // string, number, special
.collections      // array, object
.all              // Everything
.allExceptNumbers // Everything except numbers (default)
```

### Error Handling

The library provides two types of errors:

```swift
do {
    let result = try PartialJSON.parse(jsonString)
} catch let error as PartialJSONError {
    // JSON is incomplete in a way not allowed by options
    print("Incomplete JSON: \(error.message) at position \(error.position)")
} catch let error as MalformedJSONError {
    // JSON has invalid syntax
    print("Invalid JSON: \(error.message) at position \(error.position)")
}
```

## Examples

### Streaming JSON Parser

```swift
class StreamingParser {
    private var buffer = ""
    private let options: PartialJSONOptions = .all
    
    func append(_ chunk: String) -> Any? {
        buffer += chunk
        
        do {
            return try PartialJSON.parse(buffer, options: options)
        } catch {
            // Not yet complete, wait for more data
            return nil
        }
    }
}
```

### Progressive Loading

```swift
// Useful for showing partial results while loading
func loadProgressively(from chunks: [String]) {
    var accumulated = ""
    
    for chunk in chunks {
        accumulated += chunk
        
        if let partial = try? PartialJSON.parse(accumulated, options: .collections) {
            // Update UI with partial results
            updateDisplay(with: partial)
        }
    }
}
```

### API Response Handling

```swift
// Handle potentially truncated API responses
func handleAPIResponse(_ data: Data) throws -> Any {
    guard let jsonString = String(data: data, encoding: .utf8) else {
        throw APIError.invalidEncoding
    }
    
    // Try to parse even if response was truncated
    return try PartialJSON.parse(jsonString, options: .allExceptNumbers)
}
```

## Performance Considerations

- The library uses efficient `String.Index` operations for optimal performance
- First attempts to parse as complete JSON using native `JSONSerialization`
- Falls back to partial parsing only when necessary
- Minimal memory overhead with streaming-friendly design

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.5+
- Xcode 13.0+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

Run the test suite:

```bash
swift test
```

Or in Xcode:
- Press `Cmd+U` to run all tests

## Author

Ivan Trufanov

## Acknowledgments

- Inspired by the need for robust JSON parsing in streaming scenarios
- Built with Swift's powerful string handling capabilities
