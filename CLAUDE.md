# SimDeck - Project Instructions

## Overview

SimDeck is a browser-based control interface for iOS Simulator and Android Emulator. It enables AI agents with Chrome/browser access to see and interact with mobile devices.

## Tech Stack

- **Runtime**: Node.js (ES Modules)
- **Server**: Express + WebSocket (ws)
- **Frontend**: Vanilla JS, CSS (Glassmorphism), Lucide icons
- **iOS**: xcrun simctl, cliclick
- **Android**: adb

## Project Structure

```
simdeck/
├── bin/simdeck.js     # CLI entry point
├── src/
│   ├── server.js      # Express server, WebSocket streaming, API endpoints
│   └── android.js     # Android ADB control module
├── public/
│   ├── index.html     # UI
│   ├── styles.css     # Glassmorphism styling
│   └── app.js         # Frontend logic
└── package.json
```

## Key Commands

```bash
npm start              # Auto-detect and connect
npm run ios            # Force iOS Simulator
npm run android        # Force Android Emulator
```

## Development Notes

- iOS taps use `cliclick` for reliable mouse simulation (requires `brew install cliclick`)
- Screenshots stream via WebSocket at ~5 FPS
- Coordinate translation: browser coords → device logical coords → absolute screen coords
- Temp files use `simdeck-` prefix in os.tmpdir()

## Claudenv Framework

@rules/claudenv.md
