// @ts-check
const fs = require('fs');
const path = require('path');

const STORAGE_STATE_PATH = path.join(__dirname, '../.auth/adminStorageState.json');

/**
 * Ensures the browser session is authenticated as tenant admin.
 * Only logs in ONCE, caches the storage state / cookies, and reuses it across tests.
 * @param {import('@playwright/test').Page} page
 */
async function loginAsAdmin(page) {
  try {
    // 1. If storage state exists, check if cookies are already loaded
    if (fs.existsSync(STORAGE_STATE_PATH)) {
      // Test if current page already has a valid session or if we are already past login
      const currentUrl = page.url();
      if (!currentUrl.includes('/login') && currentUrl.startsWith('http://test.localhost:8000')) {
        return;
      }
    }

    // 2. Visit page; if redirected to login, perform login once and save session state
    const resp = await page.goto('/school-setup/school-class?tab=sections#sections', { waitUntil: 'domcontentloaded' }).catch(() => null);

    if (page.url().includes('/login')) {
      console.log('[Auth] Performing one-time login for admin session...');
      await page.fill('#loginEmail', 'root@tenant.com');
      await page.fill('#loginPassword', 'password');
      await Promise.all([
        page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 15000 }).catch(() => {}),
        page.click('button[type="submit"]'),
      ]);
      await page.waitForTimeout(400);

      // Save state so next test runs never need to visit /login again
      const dir = path.dirname(STORAGE_STATE_PATH);
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      await page.context().storageState({ path: STORAGE_STATE_PATH });
      console.log('[Auth] Admin session saved successfully to storage state.');
    }
  } catch (err) {
    console.error('[Auth] Login helper error:', err.message);
  }
}

module.exports = { loginAsAdmin, STORAGE_STATE_PATH };
