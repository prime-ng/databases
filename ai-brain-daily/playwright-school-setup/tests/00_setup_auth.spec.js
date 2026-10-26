// @ts-check
/**
 * 00_setup_auth.spec.js
 * Global Auth Setup — runs ONCE before all other tests.
 * Logs in as tenant admin, saves storageState to .auth/adminStorageState.json
 * so all subsequent test files reuse the same browser session cookies.
 */
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

const STORAGE_STATE_PATH = path.join(__dirname, '.auth/adminStorageState.json');
const BASE_URL = 'http://test.localhost:8000';
const LOGIN_EMAIL = 'root@tenant.com';
const LOGIN_PASSWORD = 'password';

test.describe('00 — Auth Setup (runs first, once)', () => {
  // Do NOT use storageState here — this is the test that creates it
  test.use({ storageState: undefined });

  test('TC-AUTH-01: Login as admin and save session', async ({ page }) => {
    test.setTimeout(60000);
    console.log('[AUTH] Navigating to school-setup to check session...');

    await page.goto(`${BASE_URL}/school-setup/school-class?tab=sections`, {
      waitUntil: 'domcontentloaded',
      timeout: 30000,
    });

    const currentUrl = page.url();
    console.log('[AUTH] Current URL after navigation:', currentUrl);

    if (currentUrl.includes('/login')) {
      console.log('[AUTH] Redirected to login page — performing login...');

      await expect(page.locator('#loginEmail')).toBeVisible({ timeout: 10000 });
      await page.fill('#loginEmail', LOGIN_EMAIL);
      await page.fill('#loginPassword', LOGIN_PASSWORD);

      await Promise.all([
        page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 20000 }),
        page.locator('button[type="submit"]').click(),
      ]);

      console.log('[AUTH] After login, URL:', page.url());
    } else {
      console.log('[AUTH] Already authenticated — skipping login.');
    }

    // Verify we are on the school-setup page
    await expect(page.locator('body')).not.toContainText('These credentials do not match', { timeout: 5000 }).catch(() => {});

    // Navigate to the correct page
    if (!page.url().includes('school-setup')) {
      await page.goto(`${BASE_URL}/school-setup/school-class?tab=sections`, {
        waitUntil: 'domcontentloaded',
        timeout: 20000,
      });
    }

    // Verify logged in successfully by checking the page has school-setup content
    await expect(page.locator('#sections-pane')).toBeVisible({ timeout: 15000 });

    // Save session state
    const dir = path.dirname(STORAGE_STATE_PATH);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    await page.context().storageState({ path: STORAGE_STATE_PATH });
    console.log('[AUTH] ✅ Session saved to:', STORAGE_STATE_PATH);

    // Verify file was created
    expect(fs.existsSync(STORAGE_STATE_PATH)).toBeTruthy();
  });
});
