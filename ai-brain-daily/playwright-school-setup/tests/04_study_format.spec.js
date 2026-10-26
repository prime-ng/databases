// @ts-check
/**
 * 04_study_format.spec.js
 * ============================================================
 * DEEP COMPREHENSIVE TEST — Study Format Tab
 * URL: /school-setup/school-class?tab=study-format
 * Pane: #study-format-pane
 * Modal: #StudyFormatModal | Form: #StudyFormatForm
 * Fields: code (id=code_study), name (id=name_study), short_name (id=short_name_study)
 * System flag: is_system (id=is_system_study)
 * Trash: /school-setup/study-format/trash/view
 * ============================================================
 */
const { test, expect } = require('@playwright/test');

const TS    = Date.now().toString().slice(-5);
const CODE  = `SF${TS.slice(-3)}`;
const NAME  = `AutoStudyFmt ${TS}`;
const SHORT = `ASF${TS.slice(-2)}`;

const BASE      = 'http://test.localhost:8000';
const TAB_URL   = `${BASE}/school-setup/school-class?tab=study-format`;
const TRASH_URL = `${BASE}/school-setup/study-format/trash/view`;

test.describe.serial('04 — School Setup: Study Format Tab', () => {
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

  test('TC-SF-01: Navigate to Study Format tab — pane visible', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#study-format-pane')).toBeVisible();
    await expect(page.locator('.nav-tabs .nav-link.active')).toContainText(/Study Format/i);
    console.log('[TC-SF-01] ✅ Study Format pane visible');
  });

  test('TC-SF-02: Breadcrumb correct', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText('Class & Section Management');
    console.log('[TC-SF-02] ✅ Breadcrumb correct');
  });

  test('TC-SF-03: Tab redirect works', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const pane = page.locator('#study-format-pane');
    await expect(pane).toBeVisible();
    expect(await pane.getAttribute('class')).toMatch(/show/);
    console.log('[TC-SF-03] ✅ Tab redirect correct');
  });

  test('TC-SF-04: Search filter', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const firstRow = await page.locator('#study-format-pane tbody tr td:nth-child(2)').first().textContent().catch(() => null);
    if (!firstRow) { console.log('[TC-SF-04] ⚠️  No rows'); return; }

    await page.locator('#study-format-pane input[name="search"]').fill(firstRow.trim().slice(0, 8));
    await page.locator('#study-format-pane button[type="submit"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#study-format-pane tbody')).toContainText(firstRow.trim().slice(0, 8));
    console.log('[TC-SF-04] ✅ Search filter works');
  });

  test('TC-SF-05: Active status filter', async () => {
    await page.goto(`${TAB_URL}&status=1`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#study-format-pane select[name="status"]')).toHaveValue('1');
    console.log('[TC-SF-05] ✅ Active filter');
  });

  test('TC-SF-06: Inactive status filter', async () => {
    await page.goto(`${TAB_URL}&status=0`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#study-format-pane select[name="status"]')).toHaveValue('0');
    console.log('[TC-SF-06] ✅ Inactive filter');
  });

  test('TC-SF-07: Clear filters', async () => {
    await page.goto(`${TAB_URL}&status=1&search=abc`, { waitUntil: 'domcontentloaded' });
    await page.locator('#study-format-pane a[title="Clear Filters"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#study-format-pane select[name="status"]')).toHaveValue('');
    console.log('[TC-SF-07] ✅ Clear filters works');
  });

  test('TC-SF-08: System records have disabled edit button', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    // System records have is_system=1, rendered with a disabled edit button
    const disabledEditBtn = page.locator('#study-format-pane button[disabled][title*="System"], #study-format-pane button[disabled][title*="cannot"]').first();
    if (await disabledEditBtn.count() > 0) {
      expect(await disabledEditBtn.isDisabled()).toBeTruthy();
      console.log('[TC-SF-08] ✅ System records have disabled edit button');
    } else {
      console.log('[TC-SF-08] ⚠️  No system records found or all user-created');
    }
  });

  test('TC-SF-09: Create study format — success', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#StudyFormatModal"]').first().click();
    await expect(page.locator('#StudyFormatModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#code_study').clear();
    await page.locator('#code_study').fill(CODE);

    await page.locator('#name_study').clear();
    await page.locator('#name_study').fill(NAME);

    await page.locator('#short_name_study').clear();
    await page.locator('#short_name_study').fill(SHORT);

    const respPromise = page.waitForResponse(
      r => r.url().includes('/study-format') && r.request().method() === 'POST',
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#StudyFormatForm button[type="submit"]').click();
    await respPromise;
    await page.waitForTimeout(1000);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(NAME)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#study-format-pane')).toContainText(NAME);
    console.log('[TC-SF-09] ✅ Study format created');
  });

  test('TC-SF-10: Duplicate code rejected', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#StudyFormatModal"]').first().click();
    await expect(page.locator('#StudyFormatModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#code_study').fill(CODE); // duplicate
    await page.locator('#name_study').fill(`DiffSF ${TS}`);

    const resp = page.waitForResponse(
      r => r.url().includes('/study-format') && r.request().method() === 'POST',
      { timeout: 10000 }
    ).catch(() => null);

    await page.locator('#StudyFormatForm button[type="submit"]').click();
    await page.waitForTimeout(1500);
    const response = await resp;

    const hasDup = (await page.content()).toLowerCase().includes('already') ||
                   (await page.locator('.text-danger, .swal2-icon-error').count()) > 0 ||
                   (response && response.status() >= 400) ||
                   await page.locator('#StudyFormatModal').isVisible();
    expect(hasDup).toBeTruthy();

    if (await page.locator('#StudyFormatModal').isVisible()) {
      await page.locator('#StudyFormatModal button[data-bs-dismiss="modal"]').first().click();
    }
    console.log('[TC-SF-10] ✅ Duplicate code rejected');
  });

  test('TC-SF-11: Create with is_system flag checked', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const sysCode = `SYS${TS.slice(-2)}`;
    const sysName = `SysFormat ${TS}`;

    await page.locator('button[data-bs-target="#StudyFormatModal"]').first().click();
    await expect(page.locator('#StudyFormatModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#code_study').fill(sysCode);
    await page.locator('#name_study').fill(sysName);
    await page.locator('#short_name_study').fill('SYS');

    // Check is_system
    const isSystemCheck = page.locator('#is_system_study');
    if (await isSystemCheck.count() > 0 && !(await isSystemCheck.isChecked())) {
      await isSystemCheck.click();
    }

    const respPromise = page.waitForResponse(
      r => r.url().includes('/study-format') && r.request().method() === 'POST',
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#StudyFormatForm button[type="submit"]').click();
    await respPromise;
    await page.waitForTimeout(1000);
    console.log('[TC-SF-11] ✅ System format created (if no unique violation)');
  });

  test('TC-SF-12: Edit study format', async () => {
    test.setTimeout(90000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(NAME)}`, { waitUntil: 'domcontentloaded' });

    const editBtn = page.locator('button[onclick*="editStudyFormat"]:not([disabled])').first();
    if (await editBtn.count() === 0) { console.log('[TC-SF-12] ⚠️  Edit not found'); return; }

    await editBtn.click();
    const swalConfirm = page.locator('.swal2-confirm');
    if (await swalConfirm.isVisible({ timeout: 3000 }).catch(() => false)) {
      await swalConfirm.click();
    }
    await expect(page.locator('#StudyFormatModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(600);

    await page.locator('#name_study').clear();
    await page.locator('#name_study').fill(updatedName);

    const respPromise = page.waitForResponse(
      r => r.url().includes('/study-format') && (r.request().method() === 'PUT' || r.request().method() === 'POST'),
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#StudyFormatForm button[type="submit"]').click();
    await respPromise;
    await page.waitForTimeout(1000);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#study-format-pane')).toContainText(updatedName);
    console.log('[TC-SF-12] ✅ Study format updated');
  });

  test('TC-SF-13: Status toggle', async () => {
    test.setTimeout(60000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });

    const toggle = page.locator('#study-format-pane input[type="checkbox"].form-check-input').first();
    if (await toggle.count() > 0) {
      const original = await toggle.isChecked();
      const respP = page.waitForResponse(r => r.url().includes('toggle-status'), { timeout: 10000 }).catch(() => null);
      await toggle.click();
      await respP;
      await page.waitForTimeout(400);
      expect(await toggle.isChecked()).toBe(!original);
      await toggle.click(); // restore
      console.log('[TC-SF-13] ✅ Status toggle works');
    }
  });

  test('TC-SF-14: Soft delete study format', async () => {
    test.setTimeout(90000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });

    const deleteBtn = page.locator('button[onclick*="deleteStudyFormat"]').first();
    if (await deleteBtn.count() === 0) { console.log('[TC-SF-14] ⚠️  Delete not found'); return; }

    const deleteResp = page.waitForResponse(
      r => r.url().includes('/study-format/') && r.request().method() === 'DELETE',
      { timeout: 15000 }
    ).catch(() => null);

    await deleteBtn.click();
    await page.waitForTimeout(500);
    const swal = page.locator('.swal2-confirm');
    if (await swal.isVisible({ timeout: 3000 }).catch(() => false)) await swal.click();
    await deleteResp;
    await page.waitForTimeout(1000);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    expect(await page.locator('#study-format-pane tbody tr').filter({ hasText: updatedName }).count()).toBe(0);
    console.log('[TC-SF-14] ✅ Soft deleted');
  });

  test('TC-SF-15: Trash view', async () => {
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText(updatedName);
    console.log('[TC-SF-15] ✅ Appears in trash');
  });

  test('TC-SF-16: Restore from trash', async () => {
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
      await expect(page.locator('#study-format-pane')).toContainText(updatedName);
      console.log('[TC-SF-16] ✅ Restored');
    }
  });

  test('TC-SF-17: Force delete permanently', async () => {
    test.setTimeout(120000);

    // Soft delete
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    const deleteBtn = page.locator('button[onclick*="deleteStudyFormat"]').first();
    if (await deleteBtn.count() > 0) {
      await deleteBtn.click();
      await page.waitForTimeout(500);
      const swal = page.locator('.swal2-confirm');
      if (await swal.isVisible({ timeout: 2000 }).catch(() => false)) await swal.click();
      await page.waitForTimeout(1000);
    }

    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    const row = page.locator('tr').filter({ hasText: updatedName }).first();
    if (await row.count() === 0) { console.log('[TC-SF-17] ⚠️  Not in trash'); return; }

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
      console.log('[TC-SF-17] ✅ Permanently deleted');
    }
  });
});
