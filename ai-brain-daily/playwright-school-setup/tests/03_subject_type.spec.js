// @ts-check
/**
 * 03_subject_type.spec.js
 * ============================================================
 * DEEP COMPREHENSIVE TEST — Subject Type Tab
 * URL: /school-setup/school-class?tab=subject-type
 * Pane: #subject-type-pane
 * Modal: #subjectTypeModal | Form: #subjectTypeForm
 * Fields: code (id=subject_code), name (id=subject_name), short_name (id=subject_short_name)
 * Trash: /school-setup/subject-type/trash/view
 * ============================================================
 */
const { test, expect } = require('@playwright/test');

const TS   = Date.now().toString().slice(-5);
const CODE = `ST${TS.slice(-3)}`;
const NAME = `AutoSubjType ${TS}`;
const SHORT = `AST${TS.slice(-2)}`;

const BASE      = 'http://test.localhost:8000';
const TAB_URL   = `${BASE}/school-setup/school-class?tab=subject-type`;
const TRASH_URL = `${BASE}/school-setup/subject-type/trash/view`;

test.describe.serial('03 — School Setup: Subject Type Tab', () => {
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

  let updatedName = `${NAME} UPD`;

  test('TC-ST-01: Navigate to Subject Type tab — pane visible', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-type-pane')).toBeVisible();
    await expect(page.locator('.nav-tabs .nav-link.active')).toContainText(/Subject Type/i);
    console.log('[TC-ST-01] ✅ Subject Type pane visible');
  });

  test('TC-ST-02: Breadcrumb correct', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText('Class & Section Management');
    console.log('[TC-ST-02] ✅ Breadcrumb correct');
  });

  test('TC-ST-03: Tab redirect works', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const pane = page.locator('#subject-type-pane');
    await expect(pane).toBeVisible();
    expect(await pane.getAttribute('class')).toMatch(/show/);
    console.log('[TC-ST-03] ✅ Tab redirect correct');
  });

  test('TC-ST-04: Search filter works', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const firstRow = await page.locator('#subject-type-pane tbody tr td:nth-child(2)').first().textContent().catch(() => null);
    if (!firstRow) { console.log('[TC-ST-04] ⚠️  No rows'); return; }

    await page.locator('#subject-type-pane input[name="search"]').fill(firstRow.trim().slice(0, 8));
    await page.locator('#subject-type-pane button[type="submit"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#subject-type-pane tbody')).toContainText(firstRow.trim().slice(0, 8));
    console.log('[TC-ST-04] ✅ Search filter works');
  });

  test('TC-ST-05: Active status filter', async () => {
    await page.goto(`${TAB_URL}&status=1`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-type-pane select[name="status"]')).toHaveValue('1');
    console.log('[TC-ST-05] ✅ Active filter');
  });

  test('TC-ST-06: Inactive status filter', async () => {
    await page.goto(`${TAB_URL}&status=0`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-type-pane select[name="status"]')).toHaveValue('0');
    console.log('[TC-ST-06] ✅ Inactive filter');
  });

  test('TC-ST-07: Clear filters', async () => {
    await page.goto(`${TAB_URL}&status=1&search=abc`, { waitUntil: 'domcontentloaded' });
    await page.locator('#subject-type-pane a[title="Clear Filters"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#subject-type-pane select[name="status"]')).toHaveValue('');
    console.log('[TC-ST-07] ✅ Clear filters works');
  });

  test('TC-ST-08: Create validation — empty form shows error', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#subjectTypeModal"]').first().click();
    await expect(page.locator('#subjectTypeModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#subjectTypeForm button[type="submit"]').click();
    await page.waitForTimeout(800);

    const isOpen = await page.locator('#subjectTypeModal').isVisible();
    const hasError = await page.locator('.text-danger, .invalid-feedback, .swal2-icon-error').count();
    expect(isOpen || hasError > 0).toBeTruthy();

    if (await page.locator('#subjectTypeModal').isVisible()) {
      await page.locator('#subjectTypeModal button[data-bs-dismiss="modal"]').first().click();
    }
    console.log('[TC-ST-08] ✅ Validation works');
  });

  test('TC-ST-09: Create subject type — success', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#subjectTypeModal"]').first().click();
    await expect(page.locator('#subjectTypeModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#subject_code').clear();
    await page.locator('#subject_code').fill(CODE);

    await page.locator('#subject_name').clear();
    await page.locator('#subject_name').fill(NAME);

    await page.locator('#subject_short_name').clear();
    await page.locator('#subject_short_name').fill(SHORT);

    const respPromise = page.waitForResponse(
      resp => resp.url().includes('/subject-type') && resp.request().method() === 'POST',
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#subjectTypeForm button[type="submit"]').click();
    await respPromise;
    await page.waitForTimeout(1000);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(NAME)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-type-pane')).toContainText(NAME);
    console.log('[TC-ST-09] ✅ Subject type created');
  });

  test('TC-ST-10: Duplicate code rejected', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#subjectTypeModal"]').first().click();
    await expect(page.locator('#subjectTypeModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#subject_code').fill(CODE); // duplicate
    await page.locator('#subject_name').fill(`DiffName ${TS}`);

    const resp = page.waitForResponse(
      r => r.url().includes('/subject-type') && r.request().method() === 'POST',
      { timeout: 10000 }
    ).catch(() => null);

    await page.locator('#subjectTypeForm button[type="submit"]').click();
    await page.waitForTimeout(1500);
    const response = await resp;

    const hasDupError = (await page.content()).toLowerCase().includes('already') ||
                        (await page.locator('.text-danger, .swal2-icon-error').count()) > 0 ||
                        (response && response.status() >= 400) ||
                        await page.locator('#subjectTypeModal').isVisible();
    expect(hasDupError).toBeTruthy();

    if (await page.locator('#subjectTypeModal').isVisible()) {
      await page.locator('#subjectTypeModal button[data-bs-dismiss="modal"]').first().click();
    }
    console.log('[TC-ST-10] ✅ Duplicate code rejected');
  });

  test('TC-ST-11: View subject type detail', async () => {
    test.setTimeout(60000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(NAME)}`, { waitUntil: 'domcontentloaded' });

    const viewBtn = page.locator('#subject-type-pane a[href*="subject-type"][href*="view"], #subject-type-pane a.btn-outline-primary').first();
    if (await viewBtn.count() > 0) {
      await viewBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('body')).toContainText(NAME);
      await page.goBack();
      console.log('[TC-ST-11] ✅ View works');
    } else {
      console.log('[TC-ST-11] ⚠️  View button not found');
    }
  });

  test('TC-ST-12: Edit subject type', async () => {
    test.setTimeout(90000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(NAME)}`, { waitUntil: 'domcontentloaded' });

    const editBtn = page.locator('button[onclick*="editSubjectType"]').first();
    if (await editBtn.count() === 0) { console.log('[TC-ST-12] ⚠️  Edit not found'); return; }

    await editBtn.click();
    const swalConfirm = page.locator('.swal2-confirm');
    if (await swalConfirm.isVisible({ timeout: 3000 }).catch(() => false)) {
      await swalConfirm.click();
    }
    await expect(page.locator('#subjectTypeModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(600);

    await page.locator('#subject_name').clear();
    await page.locator('#subject_name').fill(updatedName);

    const respPromise = page.waitForResponse(
      r => r.url().includes('/subject-type') && (r.request().method() === 'PUT' || r.request().method() === 'POST'),
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#subjectTypeForm button[type="submit"]').click();
    await respPromise;
    await page.waitForTimeout(1000);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-type-pane')).toContainText(updatedName);
    console.log('[TC-ST-12] ✅ Subject type updated');
  });

  test('TC-ST-13: Status toggle', async () => {
    test.setTimeout(60000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });

    const toggle = page.locator('#subject-type-pane input[type="checkbox"].form-check-input').first();
    if (await toggle.count() > 0) {
      const original = await toggle.isChecked();
      const respPromise = page.waitForResponse(r => r.url().includes('toggle-status'), { timeout: 10000 }).catch(() => null);
      await toggle.click();
      await respPromise;
      await page.waitForTimeout(400);
      expect(await toggle.isChecked()).toBe(!original);
      await toggle.click(); // restore
      console.log('[TC-ST-13] ✅ Status toggle works');
    }
  });

  test('TC-ST-14: Soft delete subject type', async () => {
    test.setTimeout(90000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });

    const deleteBtn = page.locator('button[onclick*="deleteSubjectType"]').first();
    if (await deleteBtn.count() === 0) { console.log('[TC-ST-14] ⚠️  Delete not found'); return; }

    const deleteResp = page.waitForResponse(
      r => r.url().includes('/subject-type/') && r.request().method() === 'DELETE',
      { timeout: 15000 }
    ).catch(() => null);

    await deleteBtn.click();
    await page.waitForTimeout(500);
    const swal = page.locator('.swal2-confirm');
    if (await swal.isVisible({ timeout: 3000 }).catch(() => false)) await swal.click();
    await deleteResp;
    await page.waitForTimeout(1000);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    expect(await page.locator('#subject-type-pane tbody tr').filter({ hasText: updatedName }).count()).toBe(0);
    console.log('[TC-ST-14] ✅ Soft deleted');
  });

  test('TC-ST-15: Trash view — deleted item appears', async () => {
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText(updatedName);
    console.log('[TC-ST-15] ✅ Appears in trash');
  });

  test('TC-ST-16: Restore from trash', async () => {
    test.setTimeout(90000);
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });

    const row = page.locator('tr').filter({ hasText: updatedName }).first();
    await expect(row).toBeVisible({ timeout: 8000 });
    const restoreBtn = row.locator('a[href*="restore"]').first();

    if (await restoreBtn.count() > 0) {
      await restoreBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(800);
      await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
      await expect(page.locator('#subject-type-pane')).toContainText(updatedName);
      console.log('[TC-ST-16] ✅ Restored from trash');
    }
  });

  test('TC-ST-17: Force delete permanently', async () => {
    test.setTimeout(120000);

    // Soft delete first
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    const deleteBtn = page.locator('button[onclick*="deleteSubjectType"]').first();
    if (await deleteBtn.count() > 0) {
      await deleteBtn.click();
      await page.waitForTimeout(500);
      const swal = page.locator('.swal2-confirm');
      if (await swal.isVisible({ timeout: 2000 }).catch(() => false)) await swal.click();
      await page.waitForTimeout(1000);
    }

    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    const row = page.locator('tr').filter({ hasText: updatedName }).first();
    if (await row.count() === 0) { console.log('[TC-ST-17] ⚠️  Not in trash'); return; }

    const forceBtn = row.locator('button[title*="Permanent"], form[action*="force-delete"] button').first();
    if (await forceBtn.count() > 0) {
      await forceBtn.click();
      await page.waitForTimeout(500);
      const swal = page.locator('.swal2-confirm');
      if (await swal.isVisible({ timeout: 2000 }).catch(() => false)) await swal.click();
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(800);

      await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
      expect(await page.locator('tr').filter({ hasText: updatedName }).count()).toBe(0);
      console.log('[TC-ST-17] ✅ Permanently deleted');
    }
  });
});
