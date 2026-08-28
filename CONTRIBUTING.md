# Contributing to IntentOS Mobile

Thanks for your interest in contributing to IntentOS Mobile! This document outlines guidelines and processes for contributing.

## Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/varmaakshay1995-lang/-IntentOSMobile.git
   cd -IntentOSMobile
   ```

2. **Open in Xcode:**
   ```bash
   open Package.swift
   ```
   or
   ```bash
   open .
   ```

3. **Build:**
   ```bash
   swift build
   ```

4. **Run tests:**
   ```bash
   swift test
   ```

## Code Style

- Follow Swift API Design Guidelines
- Use 4-space indentation
- Keep lines under 120 characters where possible
- Document public APIs with inline comments
- Use `@MainActor` for UI-related code

## Adding Features

### New Actions

To add a new executable action:

1. Add to `ActionDescriptor` list in `ActionExecutor`
2. Implement in the `execute(name:parameters:)` method
3. Add tests in `IntentOSKitTests`

### New Decision Types

Extend the `DecisionType` enum and update the switch statement in `IntentOSSession.sendCurrentIntent()`.

## Testing

- Write tests for new functionality
- Test with both mock and real gateways
- Verify on iOS simulator and device

## Pull Request Process

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Add/update tests
4. Update README.md if needed
5. Push to your fork
6. Create a Pull Request with a clear description

## Reporting Issues

When reporting issues, include:
- iOS version
- Device/simulator
- Steps to reproduce
- Expected vs actual behavior
- Stack trace (if applicable)

## Questions?

Open an issue or discussion in the repository.
