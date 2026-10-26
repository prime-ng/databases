// @ts-check
const { defineConfig, devices } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

const storageStatePath = path.join(__dirname, 'tests/.auth/adminStorageState.json');

module.exports = defineConfig({
  testDir: './tests',
  // Run test files in alphabetical order (00_ first, then 01_, 02_ ... etc)
  // This ensures auth setup runs before any CRUD tests
  fullyParallel: false,
  workers: 1,
  timeout: 90000,
  expect: {
    timeout: 12000,
  },
  outputDir: 'test-results',
  reporter: [
    ['list'],
    ['json', { outputFile: 'test-results/results.json' }],
    ['html', { outputFolder: 'playwright-report', open: 'never' }]
  ],
  use: {
    baseURL: 'http://test.localhost:8000',
    storageState: fs.existsSync(storageStatePath) ? storageStatePath : undefined,
    trace: 'on-first-retry',
    screenshot: 'on',
    video: 'on-first-retry',
    headless: false,
    viewport: { width: 1440, height: 900 },
    ignoreHTTPSErrors: true,
    // Human-observable speed: 500ms delay between actions
    launchOptions: {
      slowMo: 500,
    },
    actionTimeout: 15000,
    navigationTimeout: 30000,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
