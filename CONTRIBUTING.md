# Contributing to PartialJSON

Thank you for your interest in contributing to PartialJSON! We welcome contributions from the community and are grateful for any help you can provide.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request, please create an issue on GitHub. When reporting issues, please include:

- A clear and descriptive title
- A detailed description of the issue or feature request
- Steps to reproduce the issue (if applicable)
- Expected behavior vs actual behavior
- Your environment (Swift version, platform, etc.)
- Code examples or test cases that demonstrate the issue

### Pull Requests

1. **Fork the Repository**: Start by forking the repository to your GitHub account.

2. **Clone Your Fork**: 
   ```bash
   git clone https://github.com/yourusername/PartialJSON.git
   cd PartialJSON
   ```

3. **Create a Branch**: Create a new branch for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

4. **Make Your Changes**: 
   - Write clean, readable, and well-documented code
   - Follow the existing code style and conventions
   - Add or update tests as needed
   - Update documentation if you're changing behavior

5. **Test Your Changes**:
   ```bash
   swift test
   ```
   
   Or in Xcode:
   - Open the project in Xcode
   - Press `Cmd+U` to run all tests

6. **Commit Your Changes**:
   ```bash
   git add .
   git commit -m "Brief description of your changes"
   ```
   
   Write clear and meaningful commit messages that explain what you changed and why.

7. **Push to Your Fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Create a Pull Request**: 
   - Go to the original repository on GitHub
   - Click "New Pull Request"
   - Select your fork and branch
   - Provide a clear description of your changes
   - Reference any related issues

## Development Guidelines

### Code Style

- Use Swift's standard naming conventions
- Follow Apple's [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Keep functions small and focused
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Use `// MARK: -` comments to organize code sections

### Testing

- Write tests for new functionality
- Ensure all tests pass before submitting a PR
- Aim for high test coverage
- Test edge cases and error conditions
- Use descriptive test names that explain what is being tested

### Documentation

- Update the README if you're adding new features
- Add inline documentation for public APIs
- Include code examples where helpful
- Keep documentation clear and concise

## Code Review Process

1. All submissions require review before merging
2. Reviewers will provide feedback and suggestions
3. Be responsive to feedback and make requested changes
4. Once approved, your PR will be merged

## Questions?

If you have questions about contributing, feel free to:
- Open an issue for discussion
- Reach out to the maintainers
- Check existing issues and pull requests for similar topics

## Thank You!

Your contributions help make PartialJSON better for everyone. We appreciate your time and effort!
