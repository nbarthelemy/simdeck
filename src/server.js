import express from 'express';
import cors from 'cors';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { exec, spawn } from 'child_process';
import { WebSocketServer } from 'ws';
import fs from 'fs';
import os from 'os';
import * as android from './android.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function execPromise(cmd) {
  return new Promise((resolve, reject) => {
    exec(cmd, { maxBuffer: 50 * 1024 * 1024 }, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(stdout);
    });
  });
}

/**
 * Create server for device control
 * @param {number} port - Server port
 * @param {string} deviceId - Device UDID (iOS) or serial (Android)
 * @param {string} platform - 'ios' or 'android'
 */
export async function createServer(port, deviceId, platform = 'ios') {
  const app = express();

  app.use(cors());
  app.use(express.json());
  app.use(express.static(join(__dirname, '../public')));

  // Store device info
  let currentDevice = { id: deviceId, platform };
  let recordInfo = null;
  let screenDimensions = { width: 393, height: 852 }; // Default, will be updated

  // Get device info
  app.get('/api/device', async (req, res) => {
    try {
      if (platform === 'android') {
        const info = await android.getDeviceInfo(deviceId);
        res.json({ success: true, device: info, platform: 'android' });
      } else {
        // iOS
        const output = await execPromise('xcrun simctl list devices booted -j');
        const data = JSON.parse(output);

        for (const [runtime, devices] of Object.entries(data.devices)) {
          for (const device of devices) {
            if (device.udid === deviceId) {
              res.json({
                success: true,
                device: {
                  ...device,
                  runtime: runtime.split('.').pop()
                },
                platform: 'ios'
              });
              return;
            }
          }
        }
        res.json({ success: false, error: 'Device not found' });
      }
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Screenshot endpoint
  app.get('/api/screenshot', async (req, res) => {
    try {
      let base64;

      if (platform === 'android') {
        const imageBuffer = await android.screenshot(deviceId);
        base64 = imageBuffer.toString('base64');
      } else {
        // iOS
        const tmpFile = join(os.tmpdir(), `simdeck-${Date.now()}.png`);
        await execPromise(`xcrun simctl io ${deviceId} screenshot "${tmpFile}"`);
        const imageBuffer = fs.readFileSync(tmpFile);
        base64 = imageBuffer.toString('base64');
        fs.unlinkSync(tmpFile);
      }

      res.json({
        success: true,
        screenshot: `data:image/png;base64,${base64}`,
        timestamp: Date.now()
      });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Raw screenshot for streaming
  app.get('/api/screenshot.png', async (req, res) => {
    try {
      let imageBuffer;

      if (platform === 'android') {
        imageBuffer = await android.screenshot(deviceId);
      } else {
        // iOS
        const tmpFile = join(os.tmpdir(), `simdeck-${Date.now()}.png`);
        await execPromise(`xcrun simctl io ${deviceId} screenshot "${tmpFile}"`);
        imageBuffer = fs.readFileSync(tmpFile);
        fs.unlinkSync(tmpFile);
      }

      res.set('Content-Type', 'image/png');
      res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.send(imageBuffer);
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Tap at coordinates
  app.post('/api/tap', async (req, res) => {
    try {
      const { x, y } = req.body;

      if (platform === 'android') {
        await android.tap(deviceId, x, y);
      } else {
        // iOS - Use simctl's built-in touch simulation via booted device
        // First activate the Simulator, then use keyboard/mouse simulation
        const deviceWidth = screenDimensions.width;
        const deviceHeight = screenDimensions.height;

        // Method: Use AppleScript to click within the Simulator window
        // Get window info and calculate absolute screen position
        const script = `
          tell application "Simulator" to activate
          delay 0.2

          tell application "System Events"
            tell process "Simulator"
              set frontWindow to front window
              set winPos to position of frontWindow
              set winSize to size of frontWindow
              set winX to item 1 of winPos
              set winY to item 2 of winPos
              set winW to item 1 of winSize
              set winH to item 2 of winSize
            end tell
          end tell

          -- Calculate click position within the simulator content
          -- Title bar is about 28px, and the device screen fills the rest
          set titleBar to 28
          set contentW to winW
          set contentH to winH - titleBar

          -- Device logical dimensions
          set devW to ${deviceWidth}
          set devH to ${deviceHeight}

          -- Calculate scale (simulator may be scaled)
          set scaleX to contentW / devW
          set scaleY to contentH / devH
          if scaleX < scaleY then
            set scale to scaleX
          else
            set scale to scaleY
          end if

          -- Calculate offset for centering
          set scaledW to devW * scale
          set scaledH to devH * scale
          set offX to (contentW - scaledW) / 2
          set offY to (contentH - scaledH) / 2

          -- Final click position (absolute screen coordinates)
          set clickX to winX + offX + (${Math.round(x)} * scale)
          set clickY to winY + titleBar + offY + (${Math.round(y)} * scale)

          -- Use cliclick if available, otherwise use mouse keys
          try
            do shell script "/opt/homebrew/bin/cliclick c:" & (round clickX) & "," & (round clickY)
          on error
            try
              do shell script "/usr/local/bin/cliclick c:" & (round clickX) & "," & (round clickY)
            on error
              -- Fallback: use Automator/mouse cursor position
              tell application "System Events"
                set mouseLoc to {round clickX, round clickY}
                click at mouseLoc
              end tell
            end try
          end try
        `;
        await execPromise(`osascript -e '${script.replace(/'/g, "'\"'\"'")}'`);
      }

      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Swipe gesture
  app.post('/api/swipe', async (req, res) => {
    try {
      const { startX, startY, endX, endY, duration = 300 } = req.body;

      if (platform === 'android') {
        await android.swipe(deviceId, startX, startY, endX, endY, duration);
        res.json({ success: true });
      } else {
        // iOS - Basic swipe via AppleScript (limited support)
        const script = `
          tell application "Simulator"
            activate
          end tell
          delay 0.1
        `;
        await execPromise(`osascript -e '${script}'`);
        res.json({ success: true, note: 'Swipe simulation via UI' });
      }
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Type text
  app.post('/api/type', async (req, res) => {
    try {
      const { text } = req.body;

      if (platform === 'android') {
        await android.typeText(deviceId, text);
      } else {
        // iOS - Focus simulator and type using AppleScript
        const script = `
          tell application "Simulator"
            activate
          end tell
          delay 0.2
          tell application "System Events"
            keystroke "${text.replace(/"/g, '\\"')}"
          end tell
        `;
        await execPromise(`osascript -e '${script}'`);
      }

      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Press key (home, back, etc)
  app.post('/api/key', async (req, res) => {
    try {
      const { key } = req.body;

      if (platform === 'android') {
        await android.pressKey(deviceId, key);
      } else {
        // iOS
        if (key === 'home') {
          // Shift+Cmd+H for home
          const script = `
            tell application "Simulator"
              activate
            end tell
            delay 0.1
            tell application "System Events"
              key code 4 using {command down, shift down}
            end tell
          `;
          await execPromise(`osascript -e '${script}'`);
        }
      }

      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Launch app by bundle ID (iOS) or package name (Android)
  app.post('/api/launch', async (req, res) => {
    try {
      const { bundleId, packageName, activityName } = req.body;

      if (platform === 'android') {
        await android.launchApp(deviceId, packageName || bundleId, activityName);
      } else {
        // iOS
        await execPromise(`xcrun simctl launch ${deviceId} ${bundleId}`);
      }

      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Open URL
  app.post('/api/openurl', async (req, res) => {
    try {
      const { url } = req.body;

      if (platform === 'android') {
        await android.openUrl(deviceId, url);
      } else {
        // iOS
        await execPromise(`xcrun simctl openurl ${deviceId} "${url}"`);
      }

      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // List installed apps
  app.get('/api/apps', async (req, res) => {
    try {
      if (platform === 'android') {
        const packages = await android.listApps(deviceId);
        res.json({ success: true, apps: packages });
      } else {
        // iOS
        const output = await execPromise(`xcrun simctl listapps ${deviceId}`);
        res.json({ success: true, raw: output });
      }
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Get screen size
  app.get('/api/screen', async (req, res) => {
    try {
      if (platform === 'android') {
        const size = await android.getScreenSize(deviceId);
        res.json({ success: true, ...size });
      } else {
        // iOS - Get actual screen size from device info
        const output = await execPromise('xcrun simctl list devices booted -j');
        const data = JSON.parse(output);

        // Try to determine screen size from device name
        // Common iOS device logical sizes
        const deviceSizes = {
          'iPhone 15 Pro Max': { width: 430, height: 932 },
          'iPhone 15 Pro': { width: 393, height: 852 },
          'iPhone 15 Plus': { width: 430, height: 932 },
          'iPhone 15': { width: 393, height: 852 },
          'iPhone 14 Pro Max': { width: 430, height: 932 },
          'iPhone 14 Pro': { width: 393, height: 852 },
          'iPhone 14 Plus': { width: 428, height: 926 },
          'iPhone 14': { width: 390, height: 844 },
          'iPhone 13 Pro Max': { width: 428, height: 926 },
          'iPhone 13 Pro': { width: 390, height: 844 },
          'iPhone 13 mini': { width: 375, height: 812 },
          'iPhone 13': { width: 390, height: 844 },
          'iPhone 12 Pro Max': { width: 428, height: 926 },
          'iPhone 12 Pro': { width: 390, height: 844 },
          'iPhone 12 mini': { width: 375, height: 812 },
          'iPhone 12': { width: 390, height: 844 },
          'iPhone SE': { width: 375, height: 667 },
          'iPhone 17 Pro': { width: 402, height: 874 },
          'iPhone 16 Pro Max': { width: 440, height: 956 },
          'iPhone 16 Pro': { width: 402, height: 874 },
          'iPad Pro': { width: 1024, height: 1366 },
          'iPad Air': { width: 820, height: 1180 },
          'iPad mini': { width: 744, height: 1133 },
        };

        let screenSize = { width: 393, height: 852 }; // Default to iPhone 15 Pro

        // Find the device
        for (const [runtime, devices] of Object.entries(data.devices)) {
          for (const device of devices) {
            if (device.udid === deviceId) {
              // Match device name
              for (const [name, size] of Object.entries(deviceSizes)) {
                if (device.name.includes(name)) {
                  screenSize = size;
                  break;
                }
              }
              break;
            }
          }
        }

        screenDimensions = screenSize; // Store for tap calculations
        res.json({ success: true, ...screenSize });
      }
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // iOS-specific: Status bar override
  app.post('/api/statusbar', async (req, res) => {
    try {
      if (platform !== 'ios') {
        res.json({ success: false, error: 'Status bar override only available on iOS' });
        return;
      }

      const { time, battery, wifi } = req.body;
      let cmd = `xcrun simctl status_bar ${deviceId} override`;
      if (time) cmd += ` --time "${time}"`;
      if (battery) cmd += ` --batteryLevel ${battery}`;
      if (wifi !== undefined) cmd += ` --wifiMode ${wifi ? 'active' : 'failed'}`;
      await execPromise(cmd);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Start recording
  app.post('/api/record/start', async (req, res) => {
    try {
      if (platform === 'android') {
        recordInfo = android.startRecording(deviceId);
        res.json({ success: true });
      } else {
        // iOS
        const tmpFile = join(os.tmpdir(), `simdeck-recording-${Date.now()}.mp4`);
        const recordProcess = spawn('xcrun', ['simctl', 'io', deviceId, 'recordVideo', tmpFile]);
        app.locals.recordProcess = recordProcess;
        app.locals.recordFile = tmpFile;
        res.json({ success: true, file: tmpFile });
      }
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Stop recording
  app.post('/api/record/stop', async (req, res) => {
    try {
      if (platform === 'android') {
        if (!recordInfo) {
          res.json({ success: false, error: 'No recording in progress' });
          return;
        }
        const buffer = await android.stopRecording(deviceId, recordInfo);
        const base64 = buffer.toString('base64');
        recordInfo = null;
        res.json({ success: true, video: `data:video/mp4;base64,${base64}` });
      } else {
        // iOS
        if (app.locals.recordProcess) {
          app.locals.recordProcess.kill('SIGINT');
          await new Promise(r => setTimeout(r, 500));

          const file = app.locals.recordFile;
          if (fs.existsSync(file)) {
            const buffer = fs.readFileSync(file);
            const base64 = buffer.toString('base64');
            res.json({ success: true, video: `data:video/mp4;base64,${base64}` });
            return;
          }
        }
        res.json({ success: false, error: 'No recording in progress' });
      }
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Android-specific: Install APK
  app.post('/api/install', async (req, res) => {
    try {
      if (platform !== 'android') {
        res.json({ success: false, error: 'APK install only available on Android' });
        return;
      }

      const { apkPath } = req.body;
      await android.installApk(deviceId, apkPath);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Android-specific: Uninstall app
  app.post('/api/uninstall', async (req, res) => {
    try {
      if (platform !== 'android') {
        res.json({ success: false, error: 'Uninstall only available on Android' });
        return;
      }

      const { packageName } = req.body;
      await android.uninstallApp(deviceId, packageName);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Platform info endpoint
  app.get('/api/platform', (req, res) => {
    res.json({
      success: true,
      platform,
      deviceId,
      features: platform === 'android'
        ? ['tap', 'swipe', 'type', 'key', 'launch', 'openurl', 'screenshot', 'record', 'install', 'uninstall', 'elements', 'tap-element']
        : ['tap', 'swipe', 'type', 'key', 'launch', 'openurl', 'screenshot', 'record', 'statusbar']
    });
  });

  // Get UI elements (Android only for now)
  app.get('/api/elements', async (req, res) => {
    try {
      if (platform !== 'android') {
        res.json({
          success: false,
          error: 'Element detection currently only available on Android',
          elements: []
        });
        return;
      }

      const elements = await android.getElements(deviceId);
      res.json({ success: true, elements, count: elements.length });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message, elements: [] });
    }
  });

  // Tap element by text/id (Android only for now)
  app.post('/api/tap-element', async (req, res) => {
    try {
      if (platform !== 'android') {
        res.json({
          success: false,
          error: 'Element tapping currently only available on Android'
        });
        return;
      }

      const { query, exact } = req.body;
      if (!query) {
        res.status(400).json({ success: false, error: 'Query is required' });
        return;
      }

      const result = await android.tapElement(deviceId, query, { exact });
      res.json(result);
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Type into element by text/id (Android only for now)
  app.post('/api/type-element', async (req, res) => {
    try {
      if (platform !== 'android') {
        res.json({
          success: false,
          error: 'Element typing currently only available on Android'
        });
        return;
      }

      const { query, text } = req.body;
      if (!query || !text) {
        res.status(400).json({ success: false, error: 'Query and text are required' });
        return;
      }

      const result = await android.typeIntoElement(deviceId, query, text);
      res.json(result);
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  const server = app.listen(port);

  // WebSocket for real-time screenshot streaming
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws) => {
    console.log('[WS] Client connected');

    let streaming = false;
    let streamInterval = null;

    ws.on('message', async (message) => {
      const data = JSON.parse(message.toString());

      if (data.action === 'startStream') {
        if (streaming) return;
        streaming = true;

        const fps = data.fps || 5;
        const interval = 1000 / fps;

        streamInterval = setInterval(async () => {
          try {
            let base64;

            if (platform === 'android') {
              const imageBuffer = await android.screenshot(deviceId);
              base64 = imageBuffer.toString('base64');
            } else {
              // iOS
              const tmpFile = join(os.tmpdir(), `simdeck-stream-${Date.now()}.png`);
              await execPromise(`xcrun simctl io ${deviceId} screenshot "${tmpFile}"`);
              const imageBuffer = fs.readFileSync(tmpFile);
              base64 = imageBuffer.toString('base64');
              fs.unlinkSync(tmpFile);
            }

            if (ws.readyState === ws.OPEN) {
              ws.send(JSON.stringify({
                type: 'frame',
                data: base64,
                timestamp: Date.now()
              }));
            }
          } catch (err) {
            console.error('[WS] Screenshot error:', err.message);
          }
        }, interval);
      }

      if (data.action === 'stopStream') {
        streaming = false;
        if (streamInterval) {
          clearInterval(streamInterval);
          streamInterval = null;
        }
      }
    });

    ws.on('close', () => {
      console.log('[WS] Client disconnected');
      streaming = false;
      if (streamInterval) {
        clearInterval(streamInterval);
      }
    });
  });

  return server;
}
