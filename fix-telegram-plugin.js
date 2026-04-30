// Fixes a known issue where the Telegram plugin action-runtime module is missing
// from openclaw's plugin-runtime-deps directory, causing the bot to receive
// messages but fail silently when trying to send replies.
//
// Run this if your bot receives messages but never responds:
//   node fix-telegram-plugin.js

const fs = require('fs');
const path = require('path');
const os = require('os');

const ocVersion = '2026.4.26-b7fa4126fdfd';
const globalModules = path.join(os.homedir(), 'AppData', 'Roaming', 'npm', 'node_modules');
const src = path.join(globalModules, 'openclaw', 'dist', 'extensions', 'telegram');

const runtimeDeps = path.join(
  os.homedir(),
  '.openclaw',
  'plugin-runtime-deps',
  `openclaw-${ocVersion}`,
  'dist',
  'extensions',
  'telegram'
);

function copyRecursive(srcDir, destDir) {
  fs.mkdirSync(destDir, { recursive: true });
  for (const entry of fs.readdirSync(srcDir, { withFileTypes: true })) {
    const srcPath = path.join(srcDir, entry.name);
    const destPath = path.join(destDir, entry.name);
    if (entry.isDirectory()) {
      copyRecursive(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

// Find the actual runtime deps path (version may differ)
const runtimeBase = path.join(os.homedir(), '.openclaw', 'plugin-runtime-deps');
let targetDir = runtimeDeps;

if (fs.existsSync(runtimeBase)) {
  const versions = fs.readdirSync(runtimeBase);
  if (versions.length > 0) {
    targetDir = path.join(runtimeBase, versions[0], 'dist', 'extensions', 'telegram');
  }
}

if (!fs.existsSync(src)) {
  console.error('ERROR: openclaw source not found at:', src);
  console.error('Make sure openclaw is installed: npm install -g openclaw');
  process.exit(1);
}

if (fs.existsSync(targetDir)) {
  console.log('Telegram plugin already present at:', targetDir);
} else {
  console.log('Copying telegram plugin to runtime deps...');
  copyRecursive(src, targetDir);
  console.log('Done:', targetDir);
}
