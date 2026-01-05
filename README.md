# SimDeck

Browser-based control for iOS Simulator and Android Emulator. No Appium required.

## Features

- **Real-time screen streaming** - Watch your device in the browser via WebSocket
- **Tap interaction** - Click anywhere on the device screen
- **Quick actions** - Home, browser, settings, screenshot buttons
- **URL navigation** - Open URLs directly in the device browser
- **Text input** - Type text into focused fields
- **Dual platform** - Supports both iOS Simulator and Android Emulator

## Requirements

### For iOS Simulator
- macOS
- Xcode with Command Line Tools (`xcode-select --install`)
- [cliclick](https://github.com/BlueM/cliclick) for tap simulation (`brew install cliclick`)

### For Android Emulator
- Android SDK with `adb` in PATH
- At least one AVD (Android Virtual Device) created

## Installation

```bash
# Clone the repository
git clone <repo-url>
cd simdeck

# Install dependencies
npm install

# Install cliclick for iOS tap support (macOS)
brew install cliclick
```

## Usage

```bash
# Auto-detect and connect to running simulator/emulator
npm start

# Force iOS Simulator
npm run ios

# Force Android Emulator
npm run android

# Specify a device by ID
node bin/simdeck.js --device=<UDID or serial>
```

The app will:
1. Detect available platforms (Xcode/ADB)
2. Find running devices or prompt you to select one
3. Boot the device if needed
4. Start a web server on http://localhost:3000
5. Open Chrome automatically

## Architecture

```
simdeck/
├── bin/
│   └── simdeck.js      # CLI entry point
├── src/
│   ├── server.js       # Express server + WebSocket streaming
│   └── android.js      # Android ADB control module
├── public/
│   ├── index.html      # UI structure
│   ├── styles.css      # Glassmorphism styling
│   └── app.js          # Frontend logic
└── package.json
```

## How It Works

### iOS Simulator
- **Screenshots**: `xcrun simctl io <udid> screenshot`
- **Tap**: AppleScript to get window position + `cliclick` for mouse clicks
- **Home button**: `xcrun simctl ui <udid> home`
- **URL navigation**: `xcrun simctl openurl <udid> <url>`
- **Text input**: `xcrun simctl io <udid> type "<text>"`

### Android Emulator
- **Screenshots**: `adb shell screencap` + `adb pull`
- **Tap**: `adb shell input tap <x> <y>`
- **Home button**: `adb shell input keyevent KEYCODE_HOME`
- **URL navigation**: `adb shell am start -a android.intent.action.VIEW -d <url>`
- **Text input**: `adb shell input text "<text>"`

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/device` | GET | Get connected device info |
| `/api/screenshot` | GET | Get screenshot as base64 |
| `/api/screenshot.png` | GET | Get screenshot as PNG |
| `/api/tap` | POST | Tap at coordinates `{x, y}` |
| `/api/home` | POST | Press home button |
| `/api/openurl` | POST | Open URL `{url}` |
| `/api/type` | POST | Type text `{text}` |
| `/api/back` | POST | Press back (Android only) |
| `/api/elements` | GET | Get UI elements (Android only) |

WebSocket endpoint: `ws://localhost:3000` for real-time screenshot streaming.

## Troubleshooting

### iOS taps not working
1. Ensure cliclick is installed: `brew install cliclick`
2. Grant Accessibility permissions to Terminal/iTerm in System Preferences > Privacy & Security > Accessibility

### Android device not detected
1. Check ADB is running: `adb devices`
2. Ensure USB debugging is enabled on the device/emulator
3. Try restarting ADB: `adb kill-server && adb start-server`

### Port already in use
```bash
# Find process using port 3000
lsof -i :3000

# Kill it or use a different port
PORT=3001 npm start
```

## License

MIT
