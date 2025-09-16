//
//  Allow.swift
//  Partial-JSON
//
//  Created by Ivan Trufanov on 16/09/2025.
//

import Foundation

/// Options that control which JSON types can be parsed when incomplete.
/// 
/// This option set allows fine-grained control over partial parsing behavior.
/// By default, the library uses `.allExceptNumbers` which allows partial parsing
/// of all types except numbers (to avoid ambiguity with incomplete numeric values).
/// 
/// You can combine options using standard `OptionSet` operations to create
/// custom parsing behaviors for your specific use case.
///
/// ## Examples
///
/// If you don't want to allow partial objects:
/// ```swift
/// let result = try parseJSON("[{\"a\": 1, \"b\": 2}, {\"a\": 3,", options: .array)
/// // result: [["a": 1, "b": 2]]
/// ```
///
/// If you don't want to allow partial strings:
/// ```swift
/// let result = try parseJSON("[\"complete string\", \"incompl", options: .all.subtracting(.string))
/// // result: ["complete string"]
/// ```
public struct PartialJSONOptions: OptionSet {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// Allow partial strings like `"hello \u12` to be parsed as `"hello "`
    public static let string = PartialJSONOptions(rawValue: 1 << 0)
    
    /// Allow partial numbers like `123.` to be parsed as `123`
    public static let number = PartialJSONOptions(rawValue: 1 << 1)
    
    /// Allow partial arrays like `[1, 2,` to be parsed as `[1, 2]`
    public static let array = PartialJSONOptions(rawValue: 1 << 2)
    
    /// Allow partial objects like `{"a": 1, "b":` to be parsed as `{"a": 1}`
    public static let object = PartialJSONOptions(rawValue: 1 << 3)
    
    /// Allow `nu` to be parsed as `null`
    public static let null = PartialJSONOptions(rawValue: 1 << 4)
    
    /// Allow `tr` to be parsed as `true`, and `fa` to be parsed as `false`
    public static let boolean = PartialJSONOptions(rawValue: 1 << 5)
    
    /// Allow `Na` to be parsed as `NaN`
    public static let nan = PartialJSONOptions(rawValue: 1 << 6)
    
    /// Allow `Inf` to be parsed as `Infinity`
    public static let infinity = PartialJSONOptions(rawValue: 1 << 7)
    
    /// Allow `-Inf` to be parsed as `-Infinity`
    public static let negativeInfinity = PartialJSONOptions(rawValue: 1 << 8)
    
    // MARK: - Convenience Combinations
    
    /// All infinity-related options (both positive and negative)
    public static let allInfinity: PartialJSONOptions = [.infinity, .negativeInfinity]
    
    /// All special value options (null, boolean, infinity, nan)
    public static let special: PartialJSONOptions = [.null, .boolean, .allInfinity, .nan]
    
    /// All atomic value options (string, number, special)
    public static let atomic: PartialJSONOptions = [.string, .number, .special]
    
    /// All collection options (array, object)
    public static let collections: PartialJSONOptions = [.array, .object]
    
    /// All options enabled
    public static let all: PartialJSONOptions = [.atomic, .collections]
    
    /// All options except numbers (default)
    public static let allExceptNumbers: PartialJSONOptions = [.string, .special, .collections]
}
