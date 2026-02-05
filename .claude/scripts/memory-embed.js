#!/usr/bin/env node
/**
 * Memory Embedding Generator
 * Generates embeddings for observations using local transformers.js
 * Usage: node memory-embed.js <action> [args]
 *
 * Actions:
 *   embed <text>        - Generate embedding for text (returns JSON array)
 *   batch               - Process pending observations in database
 *   check               - Check if embedding model is available
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Find project root
function findProjectRoot() {
  let dir = process.cwd();
  while (dir !== '/') {
    if (fs.existsSync(path.join(dir, '.claude'))) {
      return dir;
    }
    dir = path.dirname(dir);
  }
  return null;
}

const PROJECT_ROOT = findProjectRoot();
if (!PROJECT_ROOT) {
  console.error(JSON.stringify({ error: true, message: 'Not in a claudenv project' }));
  process.exit(1);
}

const MEMORY_DIR = path.join(PROJECT_ROOT, '.claude', 'memory');
const DB_FILE = path.join(MEMORY_DIR, 'memory.db');
const VEC_PATH_FILE = path.join(MEMORY_DIR, '.vec_path');
const SQLITE3_PATH_FILE = path.join(MEMORY_DIR, '.sqlite3_path');

// Get sqlite3 path (prefer Homebrew for extension support)
function getSqlite3Path() {
  if (fs.existsSync(SQLITE3_PATH_FILE)) {
    return fs.readFileSync(SQLITE3_PATH_FILE, 'utf8').trim();
  }
  // Fallback to known locations
  const candidates = [
    '/opt/homebrew/opt/sqlite/bin/sqlite3',
    '/usr/local/opt/sqlite/bin/sqlite3',
    'sqlite3'
  ];
  for (const candidate of candidates) {
    try {
      execSync(`${candidate} --version`, { stdio: 'pipe' });
      return candidate;
    } catch (e) {
      continue;
    }
  }
  return 'sqlite3';
}

// Lazy load the embedding model
let embedder = null;
let pipeline = null;

async function loadEmbedder() {
  if (embedder) return embedder;

  try {
    // Dynamic import for ESM module
    const transformers = await import('@xenova/transformers');
    pipeline = transformers.pipeline;

    // Load the model - this will download it on first use (~90MB)
    embedder = await pipeline('feature-extraction', 'Xenova/all-MiniLM-L6-v2');
    return embedder;
  } catch (err) {
    if (err.code === 'ERR_MODULE_NOT_FOUND' || err.code === 'MODULE_NOT_FOUND') {
      console.error(JSON.stringify({
        error: true,
        message: 'Embedding model not available. Install with: npm install @xenova/transformers',
        code: 'MISSING_DEPENDENCY'
      }));
    } else {
      console.error(JSON.stringify({
        error: true,
        message: `Failed to load embedding model: ${err.message}`,
        code: 'MODEL_LOAD_ERROR'
      }));
    }
    process.exit(1);
  }
}

// Generate embedding for text
async function embed(text) {
  const model = await loadEmbedder();

  // Generate embedding with mean pooling and normalization
  const output = await model(text, { pooling: 'mean', normalize: true });

  // Convert to regular array
  return Array.from(output.data);
}

// Check if dependencies are available
async function checkDependencies() {
  const result = {
    transformersAvailable: false,
    modelLoaded: false,
    vecAvailable: false,
    vecPath: ''
  };

  // Check for transformers.js
  try {
    await import('@xenova/transformers');
    result.transformersAvailable = true;

    // Try to load the model
    try {
      await loadEmbedder();
      result.modelLoaded = true;
    } catch (e) {
      // Model not yet downloaded
    }
  } catch (e) {
    // transformers not installed
  }

  // Check for sqlite-vec
  if (fs.existsSync(VEC_PATH_FILE)) {
    const vecPath = fs.readFileSync(VEC_PATH_FILE, 'utf8').trim();
    if (vecPath && fs.existsSync(vecPath)) {
      result.vecAvailable = true;
      result.vecPath = vecPath;
    }
  }

  console.log(JSON.stringify(result));
}

// Process pending observations (those without embeddings)
async function processBatch() {
  if (!fs.existsSync(DB_FILE)) {
    console.error(JSON.stringify({
      error: true,
      message: 'Database not found. Run memory-init.sh first'
    }));
    process.exit(1);
  }

  // Check if sqlite-vec is available
  let vecPath = '';
  if (fs.existsSync(VEC_PATH_FILE)) {
    vecPath = fs.readFileSync(VEC_PATH_FILE, 'utf8').trim();
  }

  if (!vecPath || !fs.existsSync(vecPath)) {
    console.log(JSON.stringify({
      error: false,
      message: 'sqlite-vec not available, skipping embedding generation',
      processed: 0
    }));
    return;
  }

  const sqlite3 = getSqlite3Path();

  // Get pending observations (those without embeddings)
  const pendingQuery = `
    SELECT json_group_array(json_object('id', o.id, 'summary', o.summary))
    FROM observations o
    LEFT JOIN observation_embeddings oe ON o.id = oe.observation_id
    WHERE oe.observation_id IS NULL
    LIMIT 50
  `;

  let pending;
  try {
    const output = execSync(`${sqlite3} "${DB_FILE}" "${pendingQuery}"`, { encoding: 'utf8' });
    pending = JSON.parse(output.trim() || '[]');
    // Filter out null entries
    pending = pending.filter(p => p && p.id);
  } catch (e) {
    pending = [];
  }

  if (pending.length === 0) {
    console.log(JSON.stringify({
      error: false,
      message: 'No pending observations',
      processed: 0
    }));
    return;
  }

  let processed = 0;
  const now = new Date().toISOString();

  for (const obs of pending) {
    try {
      // Generate embedding
      const embedding = await embed(obs.summary);

      // Insert into vec0 table (sqlite-vec uses rowid explicitly and float array)
      const vecInsert = `INSERT INTO vec_observations(rowid, embedding) VALUES (${obs.id}, '[${embedding.join(',')}]');`;

      execSync(
        `${sqlite3} "${DB_FILE}" ".load ${vecPath}" "${vecInsert}"`,
        { encoding: 'utf8' }
      );

      // Link embedding to observation (use obs.id as vec_rowid since we set it explicitly)
      const linkQuery = `
        INSERT INTO observation_embeddings (observation_id, vss_rowid, created_at)
        VALUES (${obs.id}, ${obs.id}, '${now}')
      `;

      execSync(`${sqlite3} "${DB_FILE}" "${linkQuery}"`);
      processed++;
    } catch (e) {
      console.error(`Warning: Failed to embed observation ${obs.id}: ${e.message}`);
    }
  }

  console.log(JSON.stringify({
    error: false,
    message: `Processed ${processed} observations`,
    processed,
    remaining: pending.length - processed
  }));
}

// Main entry point
async function main() {
  const action = process.argv[2];

  switch (action) {
    case 'embed':
      const text = process.argv.slice(3).join(' ');
      if (!text) {
        console.error(JSON.stringify({ error: true, message: 'No text provided' }));
        process.exit(1);
      }
      const embedding = await embed(text);
      console.log(JSON.stringify({
        error: false,
        dimensions: embedding.length,
        embedding
      }));
      break;

    case 'batch':
      await processBatch();
      break;

    case 'check':
      await checkDependencies();
      break;

    default:
      console.log(`Usage: node memory-embed.js <action> [args]

Actions:
  embed <text>   Generate embedding for text
  batch          Process pending observations
  check          Check dependencies`);
  }
}

main().catch(err => {
  console.error(JSON.stringify({
    error: true,
    message: err.message
  }));
  process.exit(1);
});
