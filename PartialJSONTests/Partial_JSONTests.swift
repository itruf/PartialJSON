//
//  PartialJSONTests.swift
//  PartialJSONTests
//
//  Created by Ivan Trufanov on 16/09/2025.
//

import Testing
import Foundation
@testable import PartialJSON

struct PartialJSONTests {
    // MARK: - Complete JSON Parsing Tests
    
    @Test func shouldParseCompleteJSON() async throws {
        // Test with __proto__ property (similar to JS test)
        let jsonString = "{\"__proto__\": 0}"
        let result = try parse(jsonString)
        
        if let dict = result as? [String: Any] {
            #expect(dict["__proto__"] as? Int == 0)
        } else {
            Issue.record("Expected dictionary result")
        }
    }
    
    @Test func shouldParseVariousCompleteJSONTypes() async throws {
        // Test various JSON types
        let testCases: [(String, Any)] = [
            ("true", true),
            ("false", false),
            ("null", NSNull()),
            ("42", 42),
            ("3.14", 3.14),
            ("\"hello\"", "hello"),
            ("[]", []),
            ("{}", [:]),
            ("[1, 2, 3]", [1, 2, 3]),
            ("{\"a\": 1, \"b\": 2}", ["a": 1, "b": 2])
        ]
        
        for (jsonString, expected) in testCases {
            let result = try parse(jsonString)
            #expect(areEqual(result, expected), "Failed for: \(jsonString)")
        }
    }
    
    // MARK: - Partial JSON Parsing Tests
    
    @Test func shouldParsePartialJSON() async throws {
        // Test partial object
        let result1 = try parse("{\"field")
        if let dict = result1 as? [String: Any] {
            #expect(dict.isEmpty)
        } else {
            Issue.record("Expected empty dictionary")
        }
        
        // Test partial string
        let result2 = try parse("\"")
        #expect((result2 as? String)?.isEmpty == true)
        
        // Test partial array
        let result3 = try parse("[2, 3, 4")
        if let array = result3 as? [Any] {
            #expect(array.count == 2)
            #expect(array[0] as? Int == 2)
            #expect(array[1] as? Int == 3)
        } else {
            Issue.record("Expected array result")
        }
        
        // Test partial object with values
        let result4 = try parse("{\"field\": true, \"field2\"")
        if let dict = result4 as? [String: Any] {
            #expect(dict.count == 1)
            #expect(dict["field"] as? Bool == true)
        } else {
            Issue.record("Expected dictionary result")
        }
        
        // Test partial object with incomplete value
        let result5 = try parse("{\"field\": true, \"field2\":")
        if let dict = result5 as? [String: Any] {
            #expect(dict.count == 1)
            #expect(dict["field"] as? Bool == true)
        } else {
            Issue.record("Expected dictionary result")
        }
        
        // Test partial nested object
        let result6 = try parse("{\"field\": true, \"field2\":{")
        if let dict = result6 as? [String: Any] {
            #expect(dict.count == 2)
            #expect(dict["field"] as? Bool == true)
            if let nested = dict["field2"] as? [String: Any] {
                #expect(nested.isEmpty)
            } else {
                Issue.record("Expected nested empty dictionary")
            }
        } else {
            Issue.record("Expected dictionary result")
        }
        
        // Test partial nested object with content
        let result7 = try parse("{\"field\": true, \"field2\": { \"obj\": \"somestr\"")
        if let dict = result7 as? [String: Any] {
            #expect(dict.count == 2)
            #expect(dict["field"] as? Bool == true)
            if let nested = dict["field2"] as? [String: Any] {
                #expect(nested.count == 1)
                #expect(nested["obj"] as? String == "somestr")
            } else {
                Issue.record("Expected nested dictionary")
            }
        } else {
            Issue.record("Expected dictionary result")
        }
        
        // Test partial nested object with trailing comma
        let result8 = try parse("{\"field\": true, \"field2\": { \"obj\": \"somestr\",")
        if let dict = result8 as? [String: Any] {
            #expect(dict.count == 2)
            #expect(dict["field"] as? Bool == true)
            if let nested = dict["field2"] as? [String: Any] {
                #expect(nested.count == 1)
                #expect(nested["obj"] as? String == "somestr")
            } else {
                Issue.record("Expected nested dictionary")
            }
        } else {
            Issue.record("Expected dictionary result")
        }
        
        // Test partial string value
        let result9 = try parse("{\"field\": \"va")
        if let dict = result9 as? [String: Any] {
            #expect(dict.count == 1)
            #expect(dict["field"] as? String == "va")
        } else {
            Issue.record("Expected dictionary result")
        }
        
        // Test partial array with mixed types
        let result10 = try parse("[ \"v1\", 2, \"v2\", 3")
        if let array = result10 as? [Any] {
            #expect(array.count == 3)
            #expect(array[0] as? String == "v1")
            #expect(array[1] as? Int == 2)
            #expect(array[2] as? String == "v2")
        } else {
            Issue.record("Expected array result")
        }
        
        // Test partial array with incomplete number
        let result11 = try parse("[ \"v1\", 2, \"v2\", -")
        if let array = result11 as? [Any] {
            #expect(array.count == 3)
            #expect(array[0] as? String == "v1")
            #expect(array[1] as? Int == 2)
            #expect(array[2] as? String == "v2")
        } else {
            Issue.record("Expected array result")
        }
        
        // Test partial array with scientific notation
        let result12 = try parse("[1, 2e")
        if let array = result12 as? [Any] {
            #expect(array.count == 1)
            #expect(array[0] as? Int == 1)
        } else {
            Issue.record("Expected array result")
        }
    }
    
    // MARK: - Number Parsing Error Tests
    
    @Test func shouldOnlyThrowErrorsForPartialNumbers() async throws {
        // Test cases where partial numbers should throw errors
        let problematicCases = [
            "1e",
            "1e-",
            "1e+",
            "1.",
            "1.2e",
            "1.2e-",
            "1.2e+",
            "-e",
            "+e",
            ".e"
        ]
        
        for jsonString in problematicCases {
            do {
                _ = try parse(jsonString, options: .all.subtracting(.number))
                Issue.record("Expected MalformedJSONError for: \(jsonString)")
            } catch is MalformedJSONError {
                // Expected error
            } catch {
                Issue.record("Unexpected error type for: \(jsonString)")
            }
        }
    }
    
    @Test func shouldThrowErrorForIncompleteNumberWithDefaultOptions() async throws {
        // Test that "1." throws error with default options (which don't allow partial numbers)
        do {
            _ = try parse("1.")
            Issue.record("Expected MalformedJSONError for '1.' with default options")
        } catch is MalformedJSONError {
            // Expected error
        } catch {
            Issue.record("Unexpected error type for '1.' with default options")
        }
        
        // Test that "1." works when partial numbers are explicitly allowed
        let result = try parse("1.", options: .all)
        if let number = result as? Double {
            #expect(number == 1.0)
        } else {
            Issue.record("Expected number result for '1.' with partial numbers allowed")
        }
    }
    
    @Test func shouldAllowPartialNumbersWhenEnabled() async throws {
        // Test cases where partial numbers should be allowed
        let allowedCases = [
            ("1", 1.0),
            ("1.", 1.0),
            ("1.2", 1.2),
            ("-1", -1.0),
            ("1e2", 100.0)
        ]
        
        for (jsonString, expected) in allowedCases {
            let result = try parse(jsonString, options: .all)
            if let number = result as? Double {
                #expect(abs(number - expected) < 0.0001, "Failed for: \(jsonString)")
            } else {
                Issue.record("Expected number result for: \(jsonString)")
            }
        }
    }
    
    // MARK: - Edge Cases and Special Values
    
    @Test func shouldHandleSpecialValues() async throws {
        // Test partial boolean values
        let result1 = try parse("t", options: .all)
        #expect(result1 as? Bool == true)
        
        let result2 = try parse("f", options: .all)
        #expect(result2 as? Bool == false)
        
        // Test partial null
        let result3 = try parse("n", options: .all)
        #expect(result3 is NSNull)
        
        // Test partial Infinity
        let result4 = try parse("I", options: .all)
        if let number = result4 as? Double {
            #expect(number.isInfinite && number > 0)
        } else {
            Issue.record("Expected positive infinity")
        }
        
        // Test partial -Infinity
        let result5 = try parse("-I", options: .all)
        if let number = result5 as? Double {
            #expect(number.isInfinite && number < 0)
        } else {
            Issue.record("Expected negative infinity")
        }
        
        // Test partial NaN
        let result6 = try parse("N", options: .all)
        if let number = result6 as? Double {
            #expect(number.isNaN)
        } else {
            Issue.record("Expected NaN")
        }
    }
    
    @Test func shouldHandleEmptyAndWhitespace() async throws {
        // Test empty string
        do {
            _ = try parse("")
            Issue.record("Expected error for empty string")
        } catch is MalformedJSONError {
            // Expected
        } catch {
            Issue.record("Unexpected error type for empty string")
        }
        
        // Test whitespace only
        do {
            _ = try parse("   ")
            Issue.record("Expected error for whitespace only")
        } catch is MalformedJSONError {
            // Expected
        } catch {
            Issue.record("Unexpected error type for whitespace only")
        }
    }
    
    @Test func shouldRespectOptions() async throws {
        // Test that options are respected
        do {
            _ = try parse("t", options: .all.subtracting(.boolean))
            Issue.record("Expected error when boolean option is disabled")
        } catch is MalformedJSONError {
            // Expected
        } catch {
            Issue.record("Unexpected error type")
        }
        
        do {
            _ = try parse("n", options: .all.subtracting(.null))
            Issue.record("Expected error when null option is disabled")
        } catch is MalformedJSONError {
            // Expected
        } catch {
            Issue.record("Unexpected error type")
        }
    }
    
    // MARK: - Helper Functions
    
    private func areEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        if let lhsDict = lhs as? [String: Any], let rhsDict = rhs as? [String: Any] {
            return NSDictionary(dictionary: lhsDict).isEqual(to: rhsDict)
        } else if let lhsArray = lhs as? [Any], let rhsArray = rhs as? [Any] {
            return NSArray(array: lhsArray).isEqual(to: rhsArray)
        } else if let lhsString = lhs as? String, let rhsString = rhs as? String {
            return lhsString == rhsString
        } else if let lhsNumber = lhs as? NSNumber, let rhsNumber = rhs as? NSNumber {
            return lhsNumber.isEqual(to: rhsNumber)
        } else if lhs is NSNull && rhs is NSNull {
            return true
        } else if let lhsBool = lhs as? Bool, let rhsBool = rhs as? Bool {
            return lhsBool == rhsBool
        }
        return false
    }
}
