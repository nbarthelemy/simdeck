// DOM Elements
const connectBtn = document.getElementById('connectBtn');
const disconnectBtn = document.getElementById('disconnectBtn');
const connectionLabel = document.getElementById('connectionLabel');
const platformLabel = document.getElementById('platformLabel');
const statusDot = document.getElementById('statusDot');
const placeholder = document.getElementById('placeholder');
const streamImg = document.getElementById('streamImg');
const touchOverlay = document.getElementById('touchOverlay');
const coordsDisplay = document.getElementById('coords');
const deviceFrame = document.getElementById('deviceFrame');
const deviceNotch = document.getElementById('deviceNotch');
const deviceHomeIndicator = document.getElementById('deviceHomeIndicator');
const infoPill = document.getElementById('infoPill');
const deviceNameEl = document.getElementById('deviceName');

// Action buttons
const homeBtn = document.getElementById('homeBtn');
const backBtn = document.getElementById('backBtn');
const browserBtn = document.getElementById('browserBtn');
const settingsBtn = document.getElementById('settingsBtn');
const screenshotBtn = document.getElementById('screenshotBtn');

// Input elements
const urlInput = document.getElementById('urlInput');
const goBtn = document.getElementById('goBtn');
const textInput = document.getElementById('textInput');
const typeBtn = document.getElementById('typeBtn');

// Element detection
const elementsSection = document.getElementById('elementsSection');
const elementQuery = document.getElementById('elementQuery');
const tapElementBtn = document.getElementById('tapElementBtn');
const refreshElementsBtn = document.getElementById('refreshElementsBtn');
const elementsList = document.getElementById('elementsList');
const elementCount = document.getElementById('elementCount');

// State
let isConnected = false;
let ws = null;
let deviceInfo = null;
let currentPlatform = 'ios';

// Screen dimensions (for coordinate translation)
let screenDimensions = {
  display: { width: 390, height: 844 },
  device: { width: 1179, height: 2556 }
};

// API Helper
async function api(endpoint, method = 'GET', body = null) {
  const options = {
    method,
    headers: { 'Content-Type': 'application/json' }
  };
  if (body) {
    options.body = JSON.stringify(body);
  }
  const response = await fetch(`/api${endpoint}`, options);
  return response.json();
}

// Update UI for platform
function updatePlatformUI(platform) {
  currentPlatform = platform;

  if (platform === 'android') {
    platformLabel.textContent = 'Android';
    backBtn.style.display = 'flex';
    elementsSection.style.display = 'flex';

    // Android device frame styling
    deviceFrame.classList.add('android');
    deviceNotch.style.display = 'none';
    deviceHomeIndicator.style.display = 'none';
  } else {
    platformLabel.textContent = 'iOS';
    backBtn.style.display = 'none';
    elementsSection.style.display = 'none';

    // iOS device frame styling
    deviceFrame.classList.remove('android');
    deviceNotch.style.display = 'flex';
    deviceHomeIndicator.style.display = 'block';
  }
}

// Update UI based on connection state
function updateUI(connected) {
  isConnected = connected;

  if (connected) {
    statusDot.className = 'status-dot connected';
    connectionLabel.textContent = 'Connected';
    connectBtn.disabled = true;
    disconnectBtn.disabled = false;
    placeholder.style.display = 'none';
    streamImg.classList.remove('hidden');
    infoPill.style.display = 'flex';

    // Enable all action buttons
    [homeBtn, backBtn, browserBtn, settingsBtn, screenshotBtn, goBtn, typeBtn, tapElementBtn, refreshElementsBtn].forEach(btn => {
      if (btn) btn.disabled = false;
    });
    [urlInput, textInput, elementQuery].forEach(input => {
      if (input) input.disabled = false;
    });
  } else {
    statusDot.className = 'status-dot';
    connectionLabel.textContent = 'Disconnected';
    platformLabel.textContent = '--';
    connectBtn.disabled = false;
    disconnectBtn.disabled = true;
    placeholder.style.display = 'flex';
    streamImg.classList.add('hidden');
    streamImg.src = '';
    elementsSection.style.display = 'none';
    elementsList.innerHTML = '';
    infoPill.style.display = 'none';

    // Disable all action buttons
    [homeBtn, backBtn, browserBtn, settingsBtn, screenshotBtn, goBtn, typeBtn, tapElementBtn, refreshElementsBtn].forEach(btn => {
      if (btn) btn.disabled = true;
    });
    [urlInput, textInput, elementQuery].forEach(input => {
      if (input) input.disabled = true;
    });
  }
}

// Set connecting state
function setConnecting() {
  statusDot.className = 'status-dot connecting';
  connectionLabel.textContent = 'Connecting...';
  connectBtn.disabled = true;
  placeholder.classList.add('loading');
}

// Connect via WebSocket for streaming
async function connect() {
  try {
    setConnecting();

    // Get platform info first
    const platformResult = await api('/platform');
    if (platformResult.success) {
      updatePlatformUI(platformResult.platform);

      // Get screen size for both platforms
      const screenResult = await api('/screen');
      if (screenResult.success) {
        if (platformResult.platform === 'android') {
          screenDimensions.device = { width: screenResult.width, height: screenResult.height };
        } else {
          // iOS - update display dimensions
          screenDimensions.display = { width: screenResult.width, height: screenResult.height };
        }
        console.log('Screen dimensions:', screenDimensions);
      }
    }

    // Get device info
    const deviceResult = await api('/device');
    if (!deviceResult.success) {
      throw new Error('Could not get device info');
    }
    deviceInfo = deviceResult.device;
    deviceNameEl.textContent = deviceInfo.name || deviceInfo.model || 'Unknown Device';

    // Connect WebSocket
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(`${protocol}//${window.location.host}/ws`);

    ws.onopen = () => {
      console.log('WebSocket connected');
      ws.send(JSON.stringify({ action: 'startStream', fps: 8 }));
      updateUI(true);
    };

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === 'frame') {
        streamImg.src = `data:image/png;base64,${data.data}`;
      }
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
      console.log('WebSocket closed');
      if (isConnected) {
        updateUI(false);
      }
    };

  } catch (error) {
    console.error('Connection error:', error);
    alert('Failed to connect: ' + error.message);
    updateUI(false);
  }
  placeholder.classList.remove('loading');
}

// Disconnect
function disconnect() {
  if (ws) {
    ws.send(JSON.stringify({ action: 'stopStream' }));
    ws.close();
    ws = null;
  }
  updateUI(false);
}

// Handle tap
async function handleTap(e) {
  if (!isConnected) return;

  // Use the touch overlay bounds directly (it covers the screen area)
  const rect = touchOverlay.getBoundingClientRect();
  const relX = (e.clientX - rect.left) / rect.width;
  const relY = (e.clientY - rect.top) / rect.height;

  // Clamp to valid range
  const clampedRelX = Math.max(0, Math.min(1, relX));
  const clampedRelY = Math.max(0, Math.min(1, relY));

  let x, y;

  if (currentPlatform === 'android') {
    x = Math.round(clampedRelX * screenDimensions.device.width);
    y = Math.round(clampedRelY * screenDimensions.device.height);
  } else {
    x = Math.round(clampedRelX * screenDimensions.display.width);
    y = Math.round(clampedRelY * screenDimensions.display.height);
  }

  coordsDisplay.textContent = `${x}, ${y}`;

  // Visual feedback - show tap indicator
  showTapFeedback(e.clientX - rect.left, e.clientY - rect.top);

  try {
    const result = await api('/tap', 'POST', { x, y });
    console.log('Tap result:', result);
  } catch (error) {
    console.error('Tap error:', error);
  }
}

// Show visual feedback for tap
function showTapFeedback(x, y) {
  const indicator = document.createElement('div');
  indicator.className = 'tap-indicator';
  indicator.style.left = `${x}px`;
  indicator.style.top = `${y}px`;
  touchOverlay.appendChild(indicator);
  setTimeout(() => indicator.remove(), 300);
}

// Quick actions
async function pressHome() {
  if (!isConnected) return;
  try {
    await api('/key', 'POST', { key: 'home' });
  } catch (error) {
    console.error('Home error:', error);
  }
}

async function pressBack() {
  if (!isConnected) return;
  try {
    await api('/key', 'POST', { key: 'back' });
  } catch (error) {
    console.error('Back error:', error);
  }
}

async function openBrowser() {
  if (!isConnected) return;
  try {
    if (currentPlatform === 'android') {
      await api('/launch', 'POST', { packageName: 'com.android.chrome' });
    } else {
      await api('/launch', 'POST', { bundleId: 'com.apple.mobilesafari' });
    }
  } catch (error) {
    console.error('Browser error:', error);
  }
}

async function openSettings() {
  if (!isConnected) return;
  try {
    if (currentPlatform === 'android') {
      await api('/launch', 'POST', { packageName: 'com.android.settings' });
    } else {
      await api('/launch', 'POST', { bundleId: 'com.apple.Preferences' });
    }
  } catch (error) {
    console.error('Settings error:', error);
  }
}

async function takeScreenshot() {
  if (!isConnected) return;
  try {
    const result = await api('/screenshot');
    if (result.success) {
      const win = window.open();
      win.document.write(`<img src="${result.screenshot}" style="max-width:100%">`);
    }
  } catch (error) {
    console.error('Screenshot error:', error);
  }
}

async function navigateToUrl() {
  if (!isConnected) return;
  const url = urlInput.value.trim();
  if (!url) return;

  const fullUrl = url.startsWith('http') ? url : `https://${url}`;

  try {
    await api('/openurl', 'POST', { url: fullUrl });
    urlInput.value = '';
  } catch (error) {
    console.error('Navigate error:', error);
  }
}

async function typeText() {
  if (!isConnected) return;
  const text = textInput.value;
  if (!text) return;

  try {
    await api('/type', 'POST', { text });
    textInput.value = '';
  } catch (error) {
    console.error('Type error:', error);
  }
}

// Element detection functions
async function refreshElements() {
  if (!isConnected || currentPlatform !== 'android') return;

  try {
    refreshElementsBtn.disabled = true;
    const result = await api('/elements');

    if (result.success) {
      elementCount.textContent = result.count;
      renderElements(result.elements);
    } else {
      elementsList.innerHTML = `<div class="element-error">${result.error}</div>`;
    }
  } catch (error) {
    console.error('Elements error:', error);
    elementsList.innerHTML = '<div class="element-error">Failed to load elements</div>';
  } finally {
    refreshElementsBtn.disabled = false;
  }
}

function renderElements(elements) {
  const clickable = elements.filter(el => el.clickable || el.text);

  if (clickable.length === 0) {
    elementsList.innerHTML = '<div class="element-empty">No clickable elements found</div>';
    return;
  }

  const html = clickable.slice(0, 15).map(el => {
    const label = el.text || el.resourceId || el.className;
    const type = el.clickable ? '👆' : '📝';
    return `
      <div class="element-item" data-query="${escapeHtml(el.text || el.resourceId)}">
        <span class="element-type">${type}</span>
        <span class="element-label">${escapeHtml(label.substring(0, 30))}</span>
      </div>
    `;
  }).join('');

  elementsList.innerHTML = html;

  elementsList.querySelectorAll('.element-item').forEach(item => {
    item.addEventListener('click', () => {
      const query = item.dataset.query;
      if (query) tapElementByQuery(query);
    });
  });
}

function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

async function tapElementByQuery(query) {
  if (!isConnected || !query) return;

  try {
    const result = await api('/tap-element', 'POST', { query });
    if (result.success) {
      coordsDisplay.textContent = `Tapped: ${query}`;
    } else {
      alert(result.error || 'Element not found');
    }
  } catch (error) {
    console.error('Tap element error:', error);
  }
}

async function tapElementFromInput() {
  const query = elementQuery.value.trim();
  if (!query) return;
  await tapElementByQuery(query);
  elementQuery.value = '';
}

// Event listeners
connectBtn.addEventListener('click', connect);
disconnectBtn.addEventListener('click', disconnect);
touchOverlay.addEventListener('click', handleTap);

homeBtn.addEventListener('click', pressHome);
if (backBtn) backBtn.addEventListener('click', pressBack);
browserBtn.addEventListener('click', openBrowser);
settingsBtn.addEventListener('click', openSettings);
screenshotBtn.addEventListener('click', takeScreenshot);

goBtn.addEventListener('click', navigateToUrl);
urlInput.addEventListener('keypress', (e) => {
  if (e.key === 'Enter') navigateToUrl();
});

typeBtn.addEventListener('click', typeText);
textInput.addEventListener('keypress', (e) => {
  if (e.key === 'Enter') typeText();
});

if (refreshElementsBtn) refreshElementsBtn.addEventListener('click', refreshElements);
if (tapElementBtn) tapElementBtn.addEventListener('click', tapElementFromInput);
if (elementQuery) {
  elementQuery.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') tapElementFromInput();
  });
}

// Handle stream errors
streamImg.addEventListener('error', () => {
  console.log('Stream image error');
});

// Initialize
updateUI(false);

// Auto-connect on load
setTimeout(() => {
  connect();
}, 500);
