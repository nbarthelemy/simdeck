#!/usr/bin/env node

/**
 * SimDeck - iOS Simulator & Android Emulator Control
 *
 * Control mobile simulators/emulators from your browser.
 * iOS: Uses xcrun simctl (built into Xcode)
 * Android: Uses adb (from Android SDK)
 *
 * Usage: simdeck [options]
 *   --ios       Force iOS Simulator
 *   --android   Force Android Emulator
 *   --device    Specify device ID/UDID
 */

import { spawn, exec, execSync } from 'child_process';
import { createServer } from '../src/server.js';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import * as android from '../src/android.js';
import * as readline from 'readline';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const PORT = process.env.PORT || 3000;

// Parse CLI args
const args = process.argv.slice(2);
const forceIos = args.includes('--ios');
const forceAndroid = args.includes('--android');
const deviceArg = args.find(a => a.startsWith('--device='))?.split('=')[1];

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
  magenta: '\x1b[35m'
};

function log(msg, color = 'reset') {
  console.log(`${colors[color]}${msg}${colors.reset}`);
}

function logStep(step, msg) {
  console.log(`${colors.cyan}[${step}]${colors.reset} ${msg}`);
}

function execPromise(cmd) {
  return new Promise((resolve, reject) => {
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(stdout.trim());
    });
  });
}

async function checkXcode() {
  try {
    await execPromise('xcrun simctl help');
    return true;
  } catch {
    return false;
  }
}

async function checkAdb() {
  return android.checkAdb();
}

async function getBootedSimulator() {
  try {
    const output = await execPromise('xcrun simctl list devices booted -j');
    const data = JSON.parse(output);

    for (const runtime of Object.values(data.devices)) {
      for (const device of runtime) {
        if (device.state === 'Booted') {
          return { ...device, platform: 'ios' };
        }
      }
    }
    return null;
  } catch {
    return null;
  }
}

async function getAvailableSimulators() {
  try {
    const output = await execPromise('xcrun simctl list devices available -j');
    const data = JSON.parse(output);
    const devices = [];

    for (const [runtime, deviceList] of Object.entries(data.devices)) {
      if (runtime.includes('iOS')) {
        for (const device of deviceList) {
          if (device.isAvailable) {
            devices.push({
              ...device,
              runtime: runtime.split('.').pop(),
              platform: 'ios'
            });
          }
        }
      }
    }
    return devices;
  } catch {
    return [];
  }
}

async function bootSimulator(udid) {
  logStep('SIM', 'Booting iOS Simulator...');
  try {
    await execPromise(`xcrun simctl boot ${udid}`);
  } catch (e) {
    // May already be booted
  }
  // Open Simulator app
  await execPromise('open -a Simulator');
  await new Promise(resolve => setTimeout(resolve, 3000));
}

async function bootAndroidEmulator(avdName) {
  logStep('EMU', `Booting Android Emulator (${avdName})...`);
  const device = await android.bootEmulator(avdName);
  return device;
}

function promptUser(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise(resolve => {
    rl.question(question, answer => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

async function selectDevice(iosDevices, androidDevices, androidAvds) {
  console.log('');
  log('  Available Devices:', 'bright');
  console.log('');

  let index = 1;
  const deviceMap = [];

  // Running iOS Simulators
  if (iosDevices.length > 0) {
    log('  iOS Simulators (Running):', 'green');
    for (const device of iosDevices) {
      console.log(`    ${colors.cyan}${index}${colors.reset}) ${device.name} ${colors.yellow}[${device.udid.slice(0, 8)}...]${colors.reset}`);
      deviceMap.push({ ...device, platform: 'ios', running: true });
      index++;
    }
    console.log('');
  }

  // Running Android Emulators
  if (androidDevices.length > 0) {
    log('  Android Emulators (Running):', 'green');
    for (const device of androidDevices) {
      console.log(`    ${colors.cyan}${index}${colors.reset}) ${device.name} ${colors.yellow}[${device.id}]${colors.reset} - API ${device.sdkVersion || '?'}`);
      deviceMap.push({ ...device, platform: 'android', running: true });
      index++;
    }
    console.log('');
  }

  // Available iOS Simulators (not running)
  const availableIos = await getAvailableSimulators();
  const notRunningIos = availableIos.filter(d => !iosDevices.find(r => r.udid === d.udid));
  if (notRunningIos.length > 0) {
    log('  iOS Simulators (Available):', 'yellow');
    for (const device of notRunningIos.slice(0, 5)) { // Show max 5
      console.log(`    ${colors.cyan}${index}${colors.reset}) ${device.name} ${colors.yellow}[${device.runtime}]${colors.reset}`);
      deviceMap.push({ ...device, platform: 'ios', running: false });
      index++;
    }
    if (notRunningIos.length > 5) {
      console.log(`    ... and ${notRunningIos.length - 5} more`);
    }
    console.log('');
  }

  // Available Android AVDs (not running)
  const notRunningAndroid = androidAvds.filter(avd => !androidDevices.find(d => d.name === avd.name));
  if (notRunningAndroid.length > 0) {
    log('  Android AVDs (Available):', 'yellow');
    for (const avd of notRunningAndroid) {
      console.log(`    ${colors.cyan}${index}${colors.reset}) ${avd.name}`);
      deviceMap.push({ ...avd, platform: 'android', running: false, isAvd: true });
      index++;
    }
    console.log('');
  }

  if (deviceMap.length === 0) {
    return null;
  }

  const answer = await promptUser(`  Select device [1-${deviceMap.length}]: `);
  const selection = parseInt(answer);

  if (isNaN(selection) || selection < 1 || selection > deviceMap.length) {
    log('  Invalid selection, using first available device.', 'yellow');
    return deviceMap[0];
  }

  return deviceMap[selection - 1];
}

async function main() {
  console.log('');
  log('  ╔═══════════════════════════════════════════╗', 'cyan');
  log('  ║     SimDeck - Mobile Device Control       ║', 'cyan');
  log('  ║    iOS Simulator • Android Emulator       ║', 'cyan');
  log('  ║       No Appium • 100% Open Source        ║', 'cyan');
  log('  ╚═══════════════════════════════════════════╝', 'cyan');
  console.log('');

  try {
    // 1. Check available platforms
    const hasXcode = await checkXcode();
    const hasAdb = await checkAdb();

    if (hasXcode) {
      logStep('CHECK', 'Xcode simctl available ✓');
    }
    if (hasAdb) {
      logStep('CHECK', 'Android ADB available ✓');
    }

    if (!hasXcode && !hasAdb) {
      log('❌ No device control tools found.', 'red');
      log('   For iOS: Install Xcode and run: xcode-select --install', 'yellow');
      log('   For Android: Install Android Studio or SDK command-line tools', 'yellow');
      process.exit(1);
    }

    // 2. Gather available devices
    let iosDevices = [];
    let androidDevices = [];
    let androidAvds = [];

    if (hasXcode && !forceAndroid) {
      const booted = await getBootedSimulator();
      if (booted) {
        iosDevices = [booted];
      }
    }

    if (hasAdb && !forceIos) {
      androidDevices = await android.getRunningEmulators();
      androidAvds = await android.getAvailableAvds();
    }

    // 3. Select or auto-select device
    let selectedDevice = null;
    let platform = null;
    let deviceId = null;

    // If device specified via CLI
    if (deviceArg) {
      if (forceIos || (!forceAndroid && hasXcode)) {
        selectedDevice = { udid: deviceArg, platform: 'ios' };
      } else {
        selectedDevice = { id: deviceArg, platform: 'android' };
      }
    }
    // If only one platform forced or available
    else if (forceIos && iosDevices.length === 1) {
      selectedDevice = iosDevices[0];
    }
    else if (forceAndroid && androidDevices.length === 1) {
      selectedDevice = androidDevices[0];
    }
    // If only one device running total, use it
    else if (iosDevices.length + androidDevices.length === 1) {
      selectedDevice = iosDevices[0] || androidDevices[0];
    }
    // Multiple options or nothing running - prompt user
    else if (iosDevices.length + androidDevices.length > 1 ||
             (iosDevices.length + androidDevices.length === 0 &&
              (await getAvailableSimulators()).length + androidAvds.length > 0)) {
      selectedDevice = await selectDevice(iosDevices, androidDevices, androidAvds);
    }

    // 4. Boot device if needed
    if (!selectedDevice) {
      // Try to find any available device to boot
      if (hasXcode && !forceAndroid) {
        const available = await getAvailableSimulators();
        const preferred = available.find(d =>
          d.name.includes('iPhone 15') || d.name.includes('iPhone 14')
        ) || available[0];

        if (preferred) {
          await bootSimulator(preferred.udid);
          selectedDevice = { ...preferred, running: true };
        }
      }

      if (!selectedDevice && hasAdb && !forceIos) {
        if (androidAvds.length > 0) {
          selectedDevice = await bootAndroidEmulator(androidAvds[0].name);
          selectedDevice.running = true;
        }
      }

      if (!selectedDevice) {
        log('❌ No devices available.', 'red');
        log('   For iOS: Open Xcode > Settings > Platforms to download a simulator', 'yellow');
        log('   For Android: Create an AVD in Android Studio', 'yellow');
        process.exit(1);
      }
    }

    // Boot if not running
    if (!selectedDevice.running) {
      if (selectedDevice.platform === 'ios') {
        await bootSimulator(selectedDevice.udid);
        // Re-fetch device info
        const booted = await getBootedSimulator();
        if (booted) {
          selectedDevice = booted;
        }
      } else if (selectedDevice.isAvd) {
        const booted = await bootAndroidEmulator(selectedDevice.name);
        selectedDevice = booted;
      }
    }

    platform = selectedDevice.platform;
    deviceId = platform === 'ios' ? selectedDevice.udid : selectedDevice.id;

    const deviceName = selectedDevice.name || selectedDevice.model || deviceId;
    const platformLabel = platform === 'ios' ? 'iOS' : 'Android';
    logStep('DEVICE', `Connected to ${deviceName} (${platformLabel})`);

    // 5. Start web server
    logStep('SERVER', 'Starting web server...');
    const server = await createServer(PORT, deviceId, platform);
    logStep('SERVER', `Running on http://localhost:${PORT}`);

    // 6. Open browser
    logStep('BROWSER', 'Opening Chrome...');
    const openModule = await import('open');
    await openModule.default(`http://localhost:${PORT}`);

    console.log('');
    log(`  ✅ Ready! Control your ${platformLabel} device in the browser.`, 'green');
    log('  Press Ctrl+C to stop.', 'yellow');
    console.log('');

    // Handle shutdown
    process.on('SIGINT', () => {
      console.log('');
      logStep('SHUTDOWN', 'Stopping server...');
      server.close();
      process.exit(0);
    });

  } catch (error) {
    log(`❌ Error: ${error.message}`, 'red');
    console.error(error);
    process.exit(1);
  }
}

main();
