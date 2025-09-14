# Contributing to APK on Mac Guide

Thank you for your interest in contributing to this project! This guide will help you get started with contributing to the APK on Mac Guide.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Reporting Issues](#reporting-issues)
- [Suggesting Enhancements](#suggesting-enhancements)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)

## Code of Conduct

This project follows a Code of Conduct to ensure a welcoming environment for all contributors. Please be respectful and considerate in all interactions.

### Our Standards

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

There are many ways to contribute to this project:

### 🐛 Report Bugs
- Found a bug? [Open an issue](https://github.com/m-hammad-faisal/apk-on-mac-guide/issues/new)
- Include steps to reproduce, expected vs actual behavior
- Provide system information (macOS version, emulator, etc.)

### 💡 Suggest Features
- Have an idea for improvement? [Create a feature request](https://github.com/m-hammad-faisal/apk-on-mac-guide/issues/new)
- Describe the feature and its benefits
- Include mockups or examples if applicable

### 📖 Improve Documentation
- Fix typos or grammar issues
- Add missing information
- Improve existing explanations
- Add new guides or tutorials

### 🔧 Submit Code Changes
- Fix bugs or implement features
- Improve existing scripts
- Add new setup scripts for other emulators
- Enhance testing procedures

## Reporting Issues

When reporting issues, please include:

### Bug Reports
- **Title**: Clear, descriptive title
- **Description**: Detailed description of the issue
- **Steps to Reproduce**: Step-by-step instructions
- **Expected Behavior**: What should have happened
- **Actual Behavior**: What actually happened
- **Environment**:
  - macOS version
  - Emulator type and version
  - APK file details (if applicable)
  - Any relevant error messages or logs

### Example Bug Report
```
Title: BlueStacks setup script fails on macOS Monterey

Description:
The setup-bluestacks.sh script fails during installation on macOS 12.6 Monterey.

Steps to Reproduce:
1. Clone the repository
2. Run `./scripts/setup-bluestacks.sh`
3. Script fails at line 75

Expected Behavior:
BlueStacks should install successfully

Actual Behavior:
Script exits with error "brew: command not found"

Environment:
- macOS: 12.6 Monterey
- Homebrew: Not installed (this was the issue)
- Terminal: zsh
```

## Suggesting Enhancements

Enhancement suggestions should include:

- **Clear title** describing the enhancement
- **Detailed description** of the proposed feature
- **Use cases** where this would be helpful
- **Examples** or mockups if applicable
- **Implementation ideas** (optional)

## Development Setup

### Prerequisites
- macOS 10.14 or later
- Git
- Text editor or IDE
- Homebrew (recommended)

### Setup Steps
1. **Fork the repository**
   ```bash
   # Visit https://github.com/m-hammad-faisal/apk-on-mac-guide
   # Click "Fork" button
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/apk-on-mac-guide.git
   cd apk-on-mac-guide
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/m-hammad-faisal/apk-on-mac-guide.git
   ```

4. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

## Pull Request Process

### Before Submitting
1. **Test your changes** thoroughly
2. **Update documentation** if needed
3. **Follow style guidelines**
4. **Ensure scripts are executable** (`chmod +x`)
5. **Check for typos and formatting**

### Submitting the PR
1. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your branch
   - Fill out the PR template

### PR Requirements
- [ ] Clear, descriptive title
- [ ] Detailed description of changes
- [ ] Link to related issues
- [ ] Screenshots (if UI changes)
- [ ] Tests pass (if applicable)
- [ ] Documentation updated

### Example PR Description
```markdown
## Description
Adds support for NoxPlayer emulator setup with automated installation script.

## Changes Made
- Created `setup-noxplayer.sh` script
- Updated README.md with NoxPlayer instructions
- Added troubleshooting section for NoxPlayer

## Testing
- [x] Tested on macOS Big Sur (Intel)
- [x] Tested on macOS Monterey (Apple Silicon)
- [x] Verified script handles errors gracefully
- [x] Confirmed documentation is accurate

## Related Issues
Closes #15

## Screenshots
[Add screenshots if applicable]
```

## Style Guidelines

### Shell Scripts
- Use `#!/bin/bash` shebang
- Enable error handling: `set -e`
- Use descriptive variable names
- Include colored output functions
- Add usage instructions
- Handle errors gracefully

### Markdown Documentation
- Use clear, concise language
- Include code examples where helpful
- Use proper heading hierarchy
- Add table of contents for long documents
- Include links to related sections

### Code Formatting
```bash
# Good: Clear variable names and comments
EMULATOR_NAME="BlueStacks"
INSTALL_PATH="/Applications/BlueStacks.app"

# Function with clear purpose
install_bluestacks() {
    print_status "Installing $EMULATOR_NAME..."
    # Implementation
}

# Good: Error handling
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is required but not installed."
    exit 1
fi
```

### Documentation Style
- Use active voice
- Keep sentences concise
- Include examples
- Explain technical terms
- Use consistent terminology

## Testing

### Manual Testing
For script contributions:
1. Test on clean macOS installation (if possible)
2. Test with different macOS versions
3. Test both successful and error scenarios
4. Verify all output messages are helpful

For documentation:
1. Follow instructions step-by-step
2. Verify all links work
3. Check formatting renders correctly
4. Ensure examples are accurate

### Automated Testing
We're working on implementing automated testing. Contributions to testing infrastructure are welcome!

## Recognition

Contributors will be recognized in several ways:

- Listed in project README
- Mentioned in release notes
- GitHub contributor statistics
- Community recognition

## Questions?

If you have questions about contributing:

- [Open a discussion](https://github.com/m-hammad-faisal/apk-on-mac-guide/discussions)
- [Create an issue](https://github.com/m-hammad-faisal/apk-on-mac-guide/issues)
- Check existing documentation

## Thank You!

Your contributions help make this project better for everyone. Whether it's a small typo fix or a major feature addition, every contribution is valued and appreciated.

---

**Made with ❤️ by [M-Hammad-Faisal](https://github.com/m-hammad-faisal)**
