# IntentOS Mobile

A powerful iOS application framework that enables voice and screen-based intent understanding and execution using AI.

## Features

✅ **Voice Input** - Real-time speech recognition with en-IN locale support  
✅ **Screen Capture** - Live screen recording via ScreenCaptureKit (iOS 27+)  
✅ **AI Decision Engine** - Flexible backend integration for intent processing  
✅ **Action Execution** - Safe execution of approved actions (URLs, clipboard)  
✅ **SwiftUI UI** - Modern, responsive control panel  
✅ **Siri Shortcuts** - AppIntent integration for voice automation  

## Requirements

- **Xcode 15.0+**
- **iOS 17.0+** (deployment target)
- **Swift 5.9+**

## Project Structure

```
IntentOSMobile/
├── IntentOSApp/
│   └── IntentOSApp.swift          # App entry point
├── IntentOSKit/
│   └── IntentOSKit.swift          # Core framework
├── Info.plist                      # App permissions
└── README.md                       # This file
```

## Quick Start

### 1. Clone and Setup

```bash
cd /path/to/repo
open -a Xcode .
```

### 2. Configure Project Settings

In Xcode:

1. **Select the project** → Target Settings
2. **General Tab:**
   - iOS Deployment Target: `17.0` or higher
   - Supported Device Orientations: iPhone (Portrait, Landscape)

3. **Signing & Capabilities:**
   - Add `Microphone` capability
   - Add `Screen Recording` capability (for iOS 27+)

### 3. Build & Run

```bash
# Build
⌘ + B

# Run
⌘ + R
```

Or via terminal:

```bash
xcodebuild -scheme IntentOSMobile -configuration Debug
```

## Configuration

### Using Mock Gateway (Default)

The app runs in mock mode by default with no backend required:

```swift
IntentOSSession.shared.configuration = IntentOSConfiguration(
    useMockGateway: true  // Default
)
```

### Connecting Real Backend

```swift
IntentOSSession.shared.configuration = IntentOSConfiguration(
    backendURL: URL(string: "https://your-api.com/decide"),
    bearerToken: "your-bearer-token",
    useMockGateway: false
)
```

## API Reference

### IntentOSSession

Singleton managing app state:

```swift
// Request permissions
await IntentOSSession.shared.requestPermissions()

// Voice control
IntentOSSession.shared.startListening()
IntentOSSession.shared.stopListening()

// Screen sharing
IntentOSSession.shared.startScreenSharing()

// Process intents
await IntentOSSession.shared.sendCurrentIntent()
```

### Configuration Options

```swift
public struct IntentOSConfiguration {
    public var backendURL: URL?
    public var bearerToken: String?
    public var useMockGateway: Bool
}
```

### Decision Types

- `EXECUTE` - Perform an action
- `GUIDE` - Provide guidance to the user
- `ASK` - Ask for clarification
- `BLOCK` - Deny the request

## Supported Actions

| Action | Parameters | Description |
|--------|-----------|-------------|
| `open_url` | `url: String` | Open a URL or deep link |
| `copy_text` | `text: String` | Copy text to clipboard |

## Permissions

Add to `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>IntentOS needs microphone access to listen to your voice commands.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>IntentOS uses speech recognition to understand your commands.</string>

<key>NSScreenRecordingUsageDescription</key>
<string>IntentOS needs screen recording permission to capture your screen.</string>
```

## Backend Integration

### Expected Request Format

```json
{
  "text": "open google.com",
  "screenshotBase64": "...",
  "platform": "iPhone / iOS",
  "availableActions": [
    {
      "name": "open_url",
      "description": "Open an approved URL or deep link",
      "requiresConfirmation": false
    }
  ]
}
```

### Expected Response Format

```json
{
  "decision": "EXECUTE",
  "intent": "open google.com",
  "confidence": 0.95,
  "target": "google.com",
  "instruction": null,
  "action": {
    "name": "open_url",
    "parameters": {
      "url": "https://google.com"
    }
  },
  "requiresConfirmation": false,
  "response": "Opening Google"
}
```

## Development

### Adding New Actions

Edit `ActionExecutor` in `IntentOSKit.swift`:

```swift
case "your_action":
    // Implementation
    throw IntentOSError.unsupportedAction
```

### Testing Voice Recognition

```swift
// Trigger voice recording
IntentOSSession.shared.startListening()

// Observe transcript
IntentOSSession.shared.speech.onTranscript = { text in
    print("Heard: \(text)")
}
```

## Troubleshooting

### Microphone Not Working

- Ensure iOS 17.0+ deployment target
- Check `Info.plist` has `NSMicrophoneUsageDescription`
- Verify simulator Microphone is enabled (Device → Microphone)

### Screen Capture Not Available

- Requires iOS 27.0+ (or simulator iOS 27+)
- Check `NSScreenRecordingUsageDescription` in `Info.plist`
- Ensure "Screen Recording" capability is added

### Backend Connection Issues

- Verify `backendURL` is correct
- Check Bearer token format: `Bearer <token>`
- Ensure HTTPS certificate is valid
- Test with curl: `curl -H "Authorization: Bearer token" https://api.com/decide`

## License

MIT License

## Support

For issues and feature requests, open an issue on GitHub.
