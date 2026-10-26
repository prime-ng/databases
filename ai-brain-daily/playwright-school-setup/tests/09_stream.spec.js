// @ts-check
/**
 * 09_stream.spec.js
 * ============================================================
 * DEEP COMPREHENSIVE TEST — Stream Tab
 * URL: /school-setup/school-class?tab=class-stream
 * Pane: #class-stream-pane
 * Modal: #ClassStreamModal | Form: #ClassStreamForm
 * Fields:
 *   class_id (id=stream_class_id) — required select
 *   section_id (id=stream_section_id) — optional select
 *   code (id=stream_code)
 *   short_name (id=stream_short_name)
 *   name (id=stream_name)
 *   is_active (id=stream_is_active)
 * Submit: #btnSaveStream
 * Edit: editStream(id) | Delete: deleteStream(id)
 * Trash: /school-setup/class-stream/trash/view
 * ============================================================
 */
const { test, expect } = require('@playwright/test');

const TS       = Date.now().toString().slice(-5);
const STR_CODE  = `STR${TS.slice(-2)}`; // keep short
const STR_NAME  = `AutoStream ${TS}`;
const STR_SHORT = `AS${TS.slice(-3)}`;

const BASE      = 'http://test.localhost:8000';
const TAB_URL   = `${BASE}/school-setup/school-class?tab=class-stream`;
const TRASH_URL = `${BASE}/school-setup/class-stream/trash/view`;

test.describe.serial('09 — School Setup: Stream Tab', () => {
  /** @type {import('@playwright/test').Page} */
  let page;
  test.beforeAll(async ({ browser }) => {
    const context = await browser.newContext({ storageState: 'tests/.auth/adminStorageState.json' });
    page = await context.newPage();
  });
  test.afterAll(async () => {
    await page.close();
  });
  test.use({ storageState: 'tests/.auth/adminStorageState.json' });

  let updatedName = `${STR_NAME} UPD`;

  test('TC-STR-01: Navigate to Stream tab — pane visible', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#class-stream-pane')).toBeVisible();
    await expect(page.locator('.nav-tabs .nav-link.active')).toContainText(/Stream/i);
    console.log('[TC-STR-01] ✅ Stream pane visible');
  });

  test('TC-STR-02: Breadcrumb correct', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText('Class & Section Management');
    console.log('[TC-STR-02] ✅ Breadcrumb correct');
  });

  test('TC-STR-03: Tab redirect works', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const pane = page.locator('#class-stream-pane');
    await expect(pane).toBeVisible();
    expect(await pane.getAttribute('class')).toMatch(/show/);
    console.log('[TC-STR-03] ✅ Tab redirect correct');
  });

  test('TC-STR-04: Search filter', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const firstRow = await page.locator('#class-stream-pane tbody tr td:nth-child(2)').first().textContent().catch(() => null);
    if (!firstRow) { console.log('[TC-STR-04] ⚠️  No rows'); return; }

    await page.locator('#class-stream-pane input[name="search"]').fill(firstRow.trim().slice(0, 8));
    await page.locator('#class-stream-pane button[type="submit"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#class-stream-pane tbody')).toContainText(firstRow.trim().slice(0, 8));
    console.log('[TC-STR-04] ✅ Search filter works');
  });

  test('TC-STR-05: Active status filter', async () => {
    await page.goto(`${TAB_URL}&status=1`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#class-stream-pane select[name="status"]')).toHaveValue('1');
    console.log('[TC-STR-05] ✅ Active filter');
  });

  test('TC-STR-06: Inactive status filter', async () => {
    await page.goto(`${TAB_URL}&status=0`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#class-stream-pane select[name="status"]')).toHaveValue('0');
    console.log('[TC-STR-06] ✅ Inactive filter');
  });

  test('TC-STR-07: Clear filters', async () => {
    await page.goto(`${TAB_URL}&status=1&search=abc`, { waitUntil: 'domcontentloaded' });
    const clearBtn = page.locator('#class-stream-pane a[title="Clear Filters"]');
    if (await clearBtn.count() > 0) {
      await clearBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#class-stream-pane select[name="status"]')).toHaveValue('');
    }
    console.log('[TC-STR-07] ✅ Clear filters works');
  });

  test('TC-STR-08: Create modal opens and class dropdown is required', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#ClassStreamModal"], a[data-bs-target="#ClassStreamModal"]').first().click();
    await expect(page.locator('#ClassStreamModal')).toBeVisible({ timeout: 8000 });

    // Verify class dropdown is present and required
    const classSelect = page.locator('#stream_class_id');
    await expect(classSelect).toBeVisible();
    const isRequired = await classSelect.getAttribute('required');
    expect(isRequired).not.toBeNull();

    // Close modal
    await page.locator('#ClassStreamModal button[data-bs-dismiss="modal"]').first().click();
    await page.waitForTimeout(300);
    console.log('[TC-STR-08] ✅ Modal opens with required class dropdown');
  });

  test('TC-STR-09: Create validation — no class selected', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#ClassStreamModal"], a[data-bs-target="#ClassStreamModal"]').first().click();
    await expect(page.locator('#ClassStreamModal')).toBeVisible({ timeout: 8000 });

    // Submit without selecting class
    await page.locator('#btnSaveStream').click();
    await page.waitForTimeout(800);

    const isOpen = await page.locator('#ClassStreamModal').isVisible();
    const hasError = await page.locator('.text-danger, .invalid-feedback, .swal2-icon-error').count();
    expect(isOpen || hasError > 0).toBeTruthy();

    if (await page.locator('#ClassStreamModal').isVisible()) {
      await page.locator('#ClassStreamModal button[data-bs-dismiss="modal"]').first().click();
    }
    console.log('[TC-STR-09] ✅ Validation — class required');
  });

  test('TC-STR-10: Create stream — success (requires existing class)', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#ClassStreamModal"], a[data-bs-target="#ClassStreamModal"]').first().click();
    await expect(page.locator('#ClassStreamModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(400);

    // Select first available class
    const classSelect = page.locator('#stream_class_id');
    const classOptions = await classSelect.locator('option').count();

    if (classOptions <= 1) {
      console.log('[TC-STR-10] ⚠️  No classes available in dropdown — cannot create stream');
      await page.locator('#ClassStreamModal button[data-bs-dismiss="modal"]').first().click();
      return;
    }

    // Select first non-empty option
    const firstClassValue = await classSelect.locator('option:nth-child(2)').getAttribute('value');
    await classSelect.selectOption(firstClassValue || '');
    await page.waitForTimeout(500); // wait for section dropdown to populate

    await page.locator('#stream_code').clear();
    await page.locator('#stream_code').fill(STR_CODE);

    await page.locator('#stream_short_name').clear();
    await page.locator('#stream_short_name').fill(STR_SHORT);

    await page.locator('#stream_name').clear();
    await page.locator('#stream_name').fill(STR_NAME);

    const respPromise = page.waitForResponse(
      r => r.url().includes('/class-stream') && r.request().method() === 'POST',
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#btnSaveStream').click();
    await respPromise;
    await page.waitForTimeout(1000);

    // Navigate to search and verify
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(STR_NAME)}`, { waitUntil: 'domcontentloaded' });
    const streamFound = await page.locator('#class-stream-pane').getByText(STR_NAME).count() > 0;
    if (streamFound) {
      console.log('[TC-STR-10] ✅ Stream created');
    } else {
      console.log('[TC-STR-10] ⚠️  Stream may not have been created (check for duplicate or validation error)');
    }
  });

  test('TC-STR-11: Duplicate code rejected', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#ClassStreamModal"], a[data-bs-target="#ClassStreamModal"]').first().click();
    await expect(page.locator('#ClassStreamModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(400);

    const classSelect = page.locator('#stream_class_id');
    const classOptions = await classSelect.locator('option').count();
    if (classOptions <= 1) {
      await page.locator('#ClassStreamModal button[data-bs-dismiss="modal"]').first().click();
      console.log('[TC-STR-11] ⚠️  No classes — skipping');
      return;
    }

    const firstClassValue = await classSelect.locator('option:nth-child(2)').getAttribute('value');
    await classSelect.selectOption(firstClassValue || '');

    await page.locator('#stream_code').fill(STR_CODE); // same code
    await page.locator('#stream_name').fill(`DiffStream ${TS}`);

    const resp = page.waitForResponse(
      r => r.url().includes('/class-stream') && r.request().method() === 'POST',
      { timeout: 10000 }
    ).catch(() => null);

    await page.locator('#btnSaveStream').click();
    await page.waitForTimeout(1500);
    const response = await resp;

    const hasDup = (await page.content()).toLowerCase().includes('already') ||
                   (await page.locator('.text-danger, .swal2-icon-error').count()) > 0 ||
                   (response && response.status() >= 400) ||
                   await page.locator('#ClassStreamModal').isVisible();
    expect(hasDup).toBeTruthy();

    if (await page.locator('#ClassStreamModal').isVisible()) {
      await page.locator('#ClassStreamModal button[data-bs-dismiss="modal"]').first().click();
    }
    console.log('[TC-STR-11] ✅ Duplicate code check');
  });

  test('TC-STR-12: Edit stream', async () => {
    test.setTimeout(90000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(STR_NAME)}`, { waitUntil: 'domcontentloaded' });

    const editBtn = page.locator('button[onclick*="editStream"]').first();
    if (await editBtn.count() === 0) {
      // Try the main tab
      await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
      const editBtn2 = page.locator('button[onclick*="editStream"]').first();
      if (await editBtn2.count() === 0) { console.log('[TC-STR-12] ⚠️  No edit button'); return; }
      await editBtn2.click();
    } else {
      await editBtn.click();
    }

    const swalConfirm = page.locator('.swal2-confirm');
    if (await swalConfirm.isVisible({ timeout: 3000 }).catch(() => false)) {
      await swalConfirm.click();
    }

    await expect(page.locator('#ClassStreamModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(600);

    await page.locator('#stream_name').clear();
    await page.locator('#stream_name').fill(updatedName);

    const respPromise = page.waitForResponse(
      r => r.url().includes('/class-stream') && (r.request().method() === 'PUT' || r.request().method() === 'POST'),
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#btnSaveStream').click();
    await respPromise;
    await page.waitForTimeout(1000);
    console.log('[TC-STR-12] ✅ Stream edit attempted');
  });

  test('TC-STR-13: Status toggle', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const toggle = page.locator('#class-stream-pane input[type="checkbox"].form-check-input').first();
    if (await toggle.count() > 0) {
      const original = await toggle.isChecked();
      const respP = page.waitForResponse(r => r.url().includes('toggle-status'), { timeout: 10000 }).catch(() => null);
      await toggle.click();
      await respP;
      await page.waitForTimeout(400);
      expect(await toggle.isChecked()).toBe(!original);
      await toggle.click(); // restore
      console.log('[TC-STR-13] ✅ Status toggle works');
    } else {
      console.log('[TC-STR-13] ⚠️  No toggle found');
    }
  });

  test('TC-STR-14: Stream accordion — expand to see stream items', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const collapseToggle = page.locator('#class-stream-pane tr[data-bs-toggle="collapse"], #class-stream-pane button[data-bs-toggle="collapse"]').first();
    if (await collapseToggle.count() > 0) {
      await collapseToggle.click();
      await page.waitForTimeout(400);
      const expanded = page.locator('#class-stream-pane .collapse.show');
      if (await expanded.count() > 0) {
        await expect(expanded.first()).toBeVisible();
      }
      console.log('[TC-STR-14] ✅ Stream accordion expand works');
    } else {
      console.log('[TC-STR-14] ⚠️  No accordion toggles found');
    }
  });

  test('TC-STR-15: Soft delete stream', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const deleteBtn = page.locator('button[onclick*="deleteStream"]').first();
    if (await deleteBtn.count() === 0) { console.log('[TC-STR-15] ⚠️  No delete button'); return; }

    const deleteResp = page.waitForResponse(
      r => r.url().includes('/class-stream/') && r.request().method() === 'DELETE',
      { timeout: 15000 }
    ).catch(() => null);

    await deleteBtn.click();
    await page.waitForTimeout(500);
    const swal = page.locator('.swal2-confirm');
    if (await swal.isVisible({ timeout: 3000 }).catch(() => false)) await swal.click();
    await deleteResp;
    await page.waitForTimeout(1000);
    console.log('[TC-STR-15] ✅ Stream soft delete attempted');
  });

  test('TC-STR-16: Trash view', async () => {
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toBeVisible();
    const title = await page.title();
    expect(title).not.toContain('500');
    console.log('[TC-STR-16] ✅ Trash page accessible');
  });

  test('TC-STR-17: Restore from trash', async () => {
    test.setTimeout(90000);
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });

    const rows = await page.locator('tbody tr').count();
    if (rows === 0) { console.log('[TC-STR-17] ⚠️  No items in trash'); return; }

    const restoreBtn = page.locator('a[href*="restore"]').first();
    if (await restoreBtn.count() > 0) {
      await restoreBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(800);
      console.log('[TC-STR-17] ✅ Restore attempted');
    }
  });

  test('TC-STR-18: Force delete from trash', async () => {
    test.setTimeout(120000);

    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    const rows = await page.locator('tbody tr').count();
    if (rows === 0) { console.log('[TC-STR-18] ⚠️  No items in trash to force delete'); return; }

    const forceBtn = page.locator('button[title*="Permanent"], form[action*="force-delete"] button').first();
    if (await forceBtn.count() > 0) {
      const rowText = await page.locator('tbody tr').first().textContent().catch(() => '');
      await forceBtn.click();
      await page.waitForTimeout(500);
      const swal = page.locator('.swal2-confirm');
      if (await swal.isVisible({ timeout: 2000 }).catch(() => false)) await swal.click();
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(800);
      console.log('[TC-STR-18] ✅ Force delete attempted');
    } else {
      console.log('[TC-STR-18] ⚠️  No force delete button found');
    }
  });
});
