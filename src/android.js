/**
 * Android Emulator control via ADB
 *
 * Requires: Android SDK with adb in PATH
 * - Install Android Studio, or
 * - Install just command-line tools: https://developer.android.com/studio#command-tools
 */

import { exec, spawn } from 'child_process';
import fs from 'fs';
import os from 'os';
import { join } from 'path';

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
 * Check if ADB is available
 */
export async function checkAdb() {
  try {
    await execPromise('adb version');
    return true;
  } catch {
    return false;
  }
}

/**
 * Get list of running Android emulators
 */
export async function getRunningEmulators() {
  try {
    const output = await execPromise('adb devices');
    const lines = output.trim().split('\n').slice(1); // Skip header
    const devices = [];

    for (const line of lines) {
      const [id, status] = line.split('\t');
      if (id && status === 'device') {
        // Get device name/model
        let name = id;
        try {
          const model = await execPromise(`adb -s ${id} shell getprop ro.product.model`);
          const sdk = await execPromise(`adb -s ${id} shell getprop ro.build.version.sdk`);
          name = model.trim() || id;
          devices.push({
            id,
            name,
            sdkVersion: sdk.trim(),
            state: 'Running',
            type: 'android'
          });
        } catch {
          devices.push({ id, name, state: 'Running', type: 'android' });
        }
      }
    }
    return devices;
  } catch {
    return [];
  }
}

/**
 * Get list of available AVDs (Android Virtual Devices)
 */
export async function getAvailableAvds() {
  try {
    const output = await execPromise('emulator -list-avds');
    const avds = output.trim().split('\n').filter(line => line.trim());
    return avds.map(name => ({
      name,
      type: 'android',
      state: 'Shutdown'
    }));
  } catch {
    return [];
  }
}

/**
 * Boot an Android emulator by AVD name
 */
export async function bootEmulator(avdName) {
  return new Promise((resolve, reject) => {
    // Start emulator in background
    const emulatorProcess = spawn('emulator', ['-avd', avdName], {
      detached: true,
      stdio: 'ignore'
    });
    emulatorProcess.unref();

    // Wait for device to come online
    let attempts = 0;
    const maxAttempts = 60; // 60 seconds timeout

    const checkInterval = setInterval(async () => {
      attempts++;
      try {
        const devices = await getRunningEmulators();
        if (devices.length > 0) {
          clearInterval(checkInterval);
          resolve(devices[0]);
        } else if (attempts >= maxAttempts) {
          clearInterval(checkInterval);
          reject(new Error('Timeout waiting for emulator to boot'));
        }
      } catch (e) {
        if (attempts >= maxAttempts) {
          clearInterval(checkInterval);
          reject(e);
        }
      }
    }, 1000);
  });
}

/**
 * Take a screenshot from Android device
 */
export async function screenshot(deviceId) {
  const tmpFile = join(os.tmpdir(), `simdeck-android-${Date.now()}.png`);

  // Use screencap and pull (more reliable than exec-out)
  await execPromise(`adb -s ${deviceId} shell screencap -p /sdcard/simdeck_screenshot.png`);
  await execPromise(`adb -s ${deviceId} pull /sdcard/simdeck_screenshot.png "${tmpFile}"`);
  await execPromise(`adb -s ${deviceId} shell rm /sdcard/simdeck_screenshot.png`);

  const imageBuffer = fs.readFileSync(tmpFile);
  fs.unlinkSync(tmpFile);

  return imageBuffer;
}

/**
 * Tap at coordinates
 */
export async function tap(deviceId, x, y) {
  await execPromise(`adb -s ${deviceId} shell input tap ${Math.round(x)} ${Math.round(y)}`);
}

/**
 * Swipe gesture
 */
export async function swipe(deviceId, startX, startY, endX, endY, durationMs = 300) {
  await execPromise(
    `adb -s ${deviceId} shell input swipe ${Math.round(startX)} ${Math.round(startY)} ${Math.round(endX)} ${Math.round(endY)} ${durationMs}`
  );
}

/**
 * Type text
 */
export async function typeText(deviceId, text) {
  // Escape special characters for shell
  const escaped = text
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/'/g, "\\'")
    .replace(/ /g, '%s')
    .replace(/&/g, '\\&')
    .replace(/</g, '\\<')
    .replace(/>/g, '\\>')
    .replace(/\|/g, '\\|')
    .replace(/;/g, '\\;');

  await execPromise(`adb -s ${deviceId} shell input text "${escaped}"`);
}

/**
 * Press key (home, back, etc.)
 */
export async function pressKey(deviceId, key) {
  const keyMap = {
    home: 3,
    back: 4,
    menu: 82,
    power: 26,
    volumeUp: 24,
    volumeDown: 25,
    enter: 66,
    delete: 67,
    tab: 61
  };

  const keycode = keyMap[key] || key;
  await execPromise(`adb -s ${deviceId} shell input keyevent ${keycode}`);
}

/**
 * Launch app by package name
 */
export async function launchApp(deviceId, packageName, activityName = null) {
  if (activityName) {
    await execPromise(`adb -s ${deviceId} shell am start -n ${packageName}/${activityName}`);
  } else {
    // Launch using monkey (starts main activity)
    await execPromise(`adb -s ${deviceId} shell monkey -p ${packageName} -c android.intent.category.LAUNCHER 1`);
  }
}

/**
 * Open URL in browser
 */
export async function openUrl(deviceId, url) {
  await execPromise(`adb -s ${deviceId} shell am start -a android.intent.action.VIEW -d "${url}"`);
}

/**
 * List installed packages
 */
export async function listApps(deviceId) {
  const output = await execPromise(`adb -s ${deviceId} shell pm list packages -3`);
  const packages = output
    .trim()
    .split('\n')
    .map(line => line.replace('package:', '').trim())
    .filter(p => p);
  return packages;
}

/**
 * Get device info
 */
export async function getDeviceInfo(deviceId) {
  const [model, manufacturer, sdk, release] = await Promise.all([
    execPromise(`adb -s ${deviceId} shell getprop ro.product.model`).catch(() => 'Unknown'),
    execPromise(`adb -s ${deviceId} shell getprop ro.product.manufacturer`).catch(() => 'Unknown'),
    execPromise(`adb -s ${deviceId} shell getprop ro.build.version.sdk`).catch(() => 'Unknown'),
    execPromise(`adb -s ${deviceId} shell getprop ro.build.version.release`).catch(() => 'Unknown')
  ]);

  return {
    id: deviceId,
    model: model.trim(),
    manufacturer: manufacturer.trim(),
    sdkVersion: sdk.trim(),
    androidVersion: release.trim(),
    type: 'android'
  };
}

/**
 * Get screen dimensions
 */
export async function getScreenSize(deviceId) {
  const output = await execPromise(`adb -s ${deviceId} shell wm size`);
  const match = output.match(/(\d+)x(\d+)/);
  if (match) {
    return { width: parseInt(match[1]), height: parseInt(match[2]) };
  }
  return { width: 1080, height: 1920 }; // Default fallback
}

/**
 * Start screen recording
 */
export function startRecording(deviceId) {
  const tmpFile = `/sdcard/simdeck_recording_${Date.now()}.mp4`;

  const recordProcess = spawn('adb', ['-s', deviceId, 'shell', 'screenrecord', tmpFile], {
    stdio: 'pipe'
  });

  return { process: recordProcess, file: tmpFile };
}

/**
 * Stop recording and retrieve file
 */
export async function stopRecording(deviceId, recordInfo) {
  const { process: recordProcess, file: remoteFile } = recordInfo;

  // Send Ctrl+C to stop recording
  recordProcess.kill('SIGINT');

  // Wait for file to finalize
  await new Promise(r => setTimeout(r, 1000));

  // Pull file to local
  const localFile = join(os.tmpdir(), `simdeck-android-recording-${Date.now()}.mp4`);
  await execPromise(`adb -s ${deviceId} pull "${remoteFile}" "${localFile}"`);
  await execPromise(`adb -s ${deviceId} shell rm "${remoteFile}"`);

  const buffer = fs.readFileSync(localFile);
  fs.unlinkSync(localFile);

  return buffer;
}

/**
 * Install APK
 */
export async function installApk(deviceId, apkPath) {
  await execPromise(`adb -s ${deviceId} install -r "${apkPath}"`);
}

/**
 * Uninstall app
 */
export async function uninstallApp(deviceId, packageName) {
  await execPromise(`adb -s ${deviceId} uninstall ${packageName}`);
}

/**
 * Get UI elements using uiautomator
 * Returns array of clickable/interactive elements with bounds
 */
export async function getElements(deviceId) {
  const tmpFile = join(os.tmpdir(), `simdeck-ui-${Date.now()}.xml`);

  // Dump UI hierarchy
  await execPromise(`adb -s ${deviceId} shell uiautomator dump /sdcard/simdeck_ui.xml`);
  await execPromise(`adb -s ${deviceId} pull /sdcard/simdeck_ui.xml "${tmpFile}"`);
  await execPromise(`adb -s ${deviceId} shell rm /sdcard/simdeck_ui.xml`);

  // Read and parse XML
  const xmlContent = fs.readFileSync(tmpFile, 'utf-8');
  fs.unlinkSync(tmpFile);

  // Parse elements from XML
  const elements = [];
  const nodeRegex = /<node[^>]*>/g;
  let match;

  while ((match = nodeRegex.exec(xmlContent)) !== null) {
    const node = match[0];

    // Extract attributes
    const getText = (attr) => {
      const m = node.match(new RegExp(`${attr}="([^"]*)"`));
      return m ? m[1] : '';
    };

    const text = getText('text');
    const contentDesc = getText('content-desc');
    const resourceId = getText('resource-id');
    const className = getText('class');
    const clickable = getText('clickable') === 'true';
    const enabled = getText('enabled') === 'true';
    const bounds = getText('bounds');

    // Parse bounds "[left,top][right,bottom]"
    const boundsMatch = bounds.match(/\[(\d+),(\d+)\]\[(\d+),(\d+)\]/);
    if (!boundsMatch) continue;

    const [, left, top, right, bottom] = boundsMatch.map(Number);
    const centerX = Math.round((left + right) / 2);
    const centerY = Math.round((top + bottom) / 2);

    // Only include interactive or labeled elements
    if (text || contentDesc || clickable || resourceId.includes('button') ||
        className.includes('Button') || className.includes('EditText') ||
        className.includes('TextView') || className.includes('Image')) {
      elements.push({
        text: text || contentDesc || '',
        resourceId: resourceId.split('/').pop() || '',
        className: className.split('.').pop() || '',
        clickable,
        enabled,
        bounds: { left, top, right, bottom },
        center: { x: centerX, y: centerY }
      });
    }
  }

  return elements;
}

/**
 * Find element by text, content-desc, or resource-id and tap it
 */
export async function tapElement(deviceId, query, options = {}) {
  const elements = await getElements(deviceId);

  // Find matching element
  const queryLower = query.toLowerCase();
  const match = elements.find(el => {
    if (options.exact) {
      return el.text === query || el.resourceId === query;
    }
    return (
      el.text.toLowerCase().includes(queryLower) ||
      el.resourceId.toLowerCase().includes(queryLower) ||
      el.className.toLowerCase().includes(queryLower)
    );
  });

  if (!match) {
    return { success: false, error: `Element not found: ${query}` };
  }

  // Tap center of element
  await tap(deviceId, match.center.x, match.center.y);

  return {
    success: true,
    element: match,
    tappedAt: match.center
  };
}

/**
 * Find element containing text and type into it (for input fields)
 */
export async function typeIntoElement(deviceId, query, text) {
  const result = await tapElement(deviceId, query);
  if (!result.success) return result;

  // Small delay for focus
  await new Promise(r => setTimeout(r, 200));

  // Type the text
  await typeText(deviceId, text);

  return { success: true, typed: text, element: result.element };
}
