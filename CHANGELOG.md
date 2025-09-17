# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.2] - 2025-09-17

### Changed
- **BREAKING**: Renamed main parsing function from `parseJSON()` to `parse()` for cleaner API
- **BREAKING**: Changed API to use static method `PartialJSON.parse()` instead of global function
- Updated all documentation and examples to reflect the new API
- Improved README with better attribution and cleaner examples

### Removed
- Removed the convenience `parse()` function alias (now the main function)
- Removed global `parseJSON()` function

## [0.0.1] - 2025-09-16

### Added
- Initial release of PartialJSON library
- Core parsing functionality for incomplete JSON strings
- Support for partial parsing of all JSON types (objects, arrays, strings, numbers, booleans, null)
- Special numeric values support (Infinity, -Infinity, NaN)
- Configurable parsing options via `PartialJSONOptions`
- Comprehensive error handling with `PartialJSONError` and `MalformedJSONError`
- Full test coverage with Swift Testing framework
- Swift Package Manager support
- Documentation and usage examples
- GitHub Actions CI/CD workflow

### Features
- Efficient string parsing using `String.Index` for optimal performance
- Fallback mechanism: tries complete JSON parsing first, then partial
- Flexible option system with convenient presets
- Memory-efficient streaming-friendly design
