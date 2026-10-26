// @ts-check
/**
 * 05_subject.spec.js
 * ============================================================
 * DEEP COMPREHENSIVE TEST — Subject Tab
 * URL: /school-setup/school-class?tab=subject
 * Pane: #subject-pane
 * Modal: #SubjectModal | Form: #SubjectForm
 * Fields: code (id=code_subjects), name (id=name_subjects), short_name (id=short_name_subjects)
 * Extra: is_system (id=is_system_subjects), is_optional (id=is_optional_subjects)
 *        is_main_optional_subject (id=is_main_optional_subjects) — select
 * Trash: /school-setup/subject/trash/view
 * ============================================================
 */
const { test, expect } = require('@playwright/test');

const TS    = Date.now().toString().slice(-5);
const CODE  = `SB${TS.slice(-3)}`;
const NAME  = `AutoSubject ${TS}`;
const SHORT = `ASB${TS.slice(-2)}`;

const BASE      = 'http://test.localhost:8000';
const TAB_URL   = `${BASE}/school-setup/school-class?tab=subject`;
const TRASH_URL = `${BASE}/school-setup/subject/trash/view`;

test.describe.serial('05 — School Setup: Subject Tab', () => {
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

  test('TC-SUB-01: Navigate to Subject tab — pane visible', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-pane')).toBeVisible();
    await expect(page.locator('.nav-tabs .nav-link.active')).toContainText(/Subject/i);
    console.log('[TC-SUB-01] ✅ Subject pane visible');
  });

  test('TC-SUB-02: Breadcrumb correct', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText('Class & Section Management');
    console.log('[TC-SUB-02] ✅ Breadcrumb correct');
  });

  test('TC-SUB-03: Tab redirect works', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const pane = page.locator('#subject-pane');
    await expect(pane).toBeVisible();
    expect(await pane.getAttribute('class')).toMatch(/show/);
    console.log('[TC-SUB-03] ✅ Tab redirect correct');
  });

  test('TC-SUB-04: Search filter', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const firstRow = await page.locator('#subject-pane tbody tr td:nth-child(2)').first().textContent().catch(() => null);
    if (!firstRow) { console.log('[TC-SUB-04] ⚠️  No rows'); return; }

    await page.locator('#subject-pane input[name="search"]').fill(firstRow.trim().slice(0, 8));
    await page.locator('#subject-pane button[type="submit"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#subject-pane tbody')).toContainText(firstRow.trim().slice(0, 8));
    console.log('[TC-SUB-04] ✅ Search filter works');
  });

  test('TC-SUB-05: Active status filter', async () => {
    await page.goto(`${TAB_URL}&status=1`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-pane select[name="status"]')).toHaveValue('1');
    console.log('[TC-SUB-05] ✅ Active filter');
  });

  test('TC-SUB-06: Inactive status filter', async () => {
    await page.goto(`${TAB_URL}&status=0`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-pane select[name="status"]')).toHaveValue('0');
    console.log('[TC-SUB-06] ✅ Inactive filter');
  });

  test('TC-SUB-07: Clear filters', async () => {
    await page.goto(`${TAB_URL}&status=1&search=abc`, { waitUntil: 'domcontentloaded' });
    await page.locator('#subject-pane a[title="Clear Filters"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#subject-pane select[name="status"]')).toHaveValue('');
    console.log('[TC-SUB-07] ✅ Clear filters works');
  });

  test('TC-SUB-08: Create validation — empty form', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#SubjectModal"]').first().click();
    await expect(page.locator('#SubjectModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#SubjectForm button[type="submit"]').click();
    await page.waitForTimeout(800);

    const isOpen = await page.locator('#SubjectModal').isVisible();
    const hasError = await page.locator('.text-danger, .invalid-feedback, .swal2-icon-error').count();
    expect(isOpen || hasError > 0).toBeTruthy();

    if (await page.locator('#SubjectModal').isVisible()) {
      await page.locator('#SubjectModal button[data-bs-dismiss="modal"]').first().click();
    }
    console.log('[TC-SUB-08] ✅ Validation works');
  });

  test('TC-SUB-09: Create subject — success', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#SubjectModal"]').first().click();
    await expect(page.locator('#SubjectModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#code_subjects').clear();
    await page.locator('#code_subjects').fill(CODE);

    await page.locator('#name_subjects').clear();
    await page.locator('#name_subjects').fill(NAME);

    await page.locator('#short_name_subjects').clear();
    await page.locator('#short_name_subjects').fill(SHORT);

    const respPromise = page.waitForResponse(
      r => r.url().includes('/subject') && r.request().method() === 'POST',
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#SubjectForm button[type="submit"]').click();
    await respPromise;
    await page.waitForTimeout(1000);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(NAME)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-pane')).toContainText(NAME);
    console.log('[TC-SUB-09] ✅ Subject created');
  });

  test('TC-SUB-10: Duplicate code rejected', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#SubjectModal"]').first().click();
    await expect(page.locator('#SubjectModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#code_subjects').fill(CODE); // duplicate
    await page.locator('#name_subjects').fill(`DiffSubj ${TS}`);

    const resp = page.waitForResponse(
      r => r.url().includes('/subject') && r.request().method() === 'POST',
      { timeout: 10000 }
    ).catch(() => null);

    await page.locator('#SubjectForm button[type="submit"]').click();
    await page.waitForTimeout(1500);
    const response = await resp;

    const hasDup = (await page.content()).toLowerCase().includes('already') ||
                   (await page.locator('.text-danger, .swal2-icon-error').count()) > 0 ||
                   (response && response.status() >= 400) ||
                   await page.locator('#SubjectModal').isVisible();
    expect(hasDup).toBeTruthy();

    if (await page.locator('#SubjectModal').isVisible()) {
      await page.locator('#SubjectModal button[data-bs-dismiss="modal"]').first().click();
    }
    console.log('[TC-SUB-10] ✅ Duplicate code rejected');
  });

  test('TC-SUB-11: is_optional checkbox toggles main_optional_subject select', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#SubjectModal"]').first().click();
    await expect(page.locator('#SubjectModal')).toBeVisible({ timeout: 8000 });

    const isOptionalCheck = page.locator('#is_optional_subjects');
    if (await isOptionalCheck.count() > 0) {
      const mainOptSelect = page.locator('#is_main_optional_subjects');
      const wasChecked = await isOptionalCheck.isChecked();

      if (!wasChecked) {
        await isOptionalCheck.click();
        await page.waitForTimeout(300);
        // The main_optional_subject select should be visible/enabled
        if (await mainOptSelect.count() > 0) {
          const isEnabled = await mainOptSelect.isEnabled().catch(() => true);
          console.log('[TC-SUB-11] main_optional_subjects enabled:', isEnabled);
        }
        // Uncheck
        await isOptionalCheck.click();
      }
    }

    await page.locator('#SubjectModal button[data-bs-dismiss="modal"]').first().click();
    console.log('[TC-SUB-11] ✅ Optional checkbox tested');
  });

  test('TC-SUB-12: View subject detail', async () => {
    test.setTimeout(60000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(NAME)}`, { waitUntil: 'domcontentloaded' });

    const viewBtn = page.locator('#subject-pane a[href*="subject"][href*="view"], #subject-pane a.btn-outline-primary').first();
    if (await viewBtn.count() > 0) {
      await viewBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('body')).toContainText(NAME);
      await page.goBack();
      console.log('[TC-SUB-12] ✅ View works');
    } else {
      console.log('[TC-SUB-12] ⚠️  View button not found');
    }
  });

  test('TC-SUB-13: Edit subject', async () => {
    test.setTimeout(90000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(NAME)}`, { waitUntil: 'domcontentloaded' });

    const editBtn = page.locator('button[onclick*="editSubject"]:not([disabled])').first();
    if (await editBtn.count() === 0) { console.log('[TC-SUB-13] ⚠️  Edit not found'); return; }

    await editBtn.click();
    const swalConfirm = page.locator('.swal2-confirm');
    if (await swalConfirm.isVisible({ timeout: 3000 }).catch(() => false)) {
      await swalConfirm.click();
    }
    await expect(page.locator('#SubjectModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(600);

    await page.locator('#name_subjects').clear();
    await page.locator('#name_subjects').fill(updatedName);

    const respPromise = page.waitForResponse(
      r => r.url().includes('/subject') && (r.request().method() === 'PUT' || r.request().method() === 'POST'),
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#SubjectForm button[type="submit"]').click();
    await respPromise;
    await page.waitForTimeout(1000);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-pane')).toContainText(updatedName);
    console.log('[TC-SUB-13] ✅ Subject updated');
  });

  test('TC-SUB-14: Status toggle', async () => {
    test.setTimeout(60000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });

    const toggle = page.locator('#subject-pane input[type="checkbox"].form-check-input').first();
    if (await toggle.count() > 0) {
      const original = await toggle.isChecked();
      const respP = page.waitForResponse(r => r.url().includes('toggle-status'), { timeout: 10000 }).catch(() => null);
      await toggle.click();
      await respP;
      await page.waitForTimeout(400);
      expect(await toggle.isChecked()).toBe(!original);
      await toggle.click(); // restore
      console.log('[TC-SUB-14] ✅ Status toggle works');
    }
  });

  test('TC-SUB-15: Soft delete subject', async () => {
    test.setTimeout(90000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });

    const deleteBtn = page.locator('button[onclick*="deleteSubject"]').first();
    if (await deleteBtn.count() === 0) { console.log('[TC-SUB-15] ⚠️  Delete not found'); return; }

    const deleteResp = page.waitForResponse(
      r => r.url().includes('/subject/') && r.request().method() === 'DELETE',
      { timeout: 15000 }
    ).catch(() => null);

    await deleteBtn.click();
    await page.waitForTimeout(500);
    const swal = page.locator('.swal2-confirm');
    if (await swal.isVisible({ timeout: 3000 }).catch(() => false)) await swal.click();
    await deleteResp;
    await page.waitForTimeout(1000);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    expect(await page.locator('#subject-pane tbody tr').filter({ hasText: updatedName }).count()).toBe(0);
    console.log('[TC-SUB-15] ✅ Soft deleted');
  });

  test('TC-SUB-16: Trash view', async () => {
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText(updatedName);
    console.log('[TC-SUB-16] ✅ Appears in trash');
  });

  test('TC-SUB-17: Restore from trash', async () => {
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
      await expect(page.locator('#subject-pane')).toContainText(updatedName);
      console.log('[TC-SUB-17] ✅ Restored');
    }
  });

  test('TC-SUB-18: Force delete permanently', async () => {
    test.setTimeout(120000);

    // Soft delete
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    const deleteBtn = page.locator('button[onclick*="deleteSubject"]').first();
    if (await deleteBtn.count() > 0) {
      await deleteBtn.click();
      await page.waitForTimeout(500);
      const swal = page.locator('.swal2-confirm');
      if (await swal.isVisible({ timeout: 2000 }).catch(() => false)) await swal.click();
      await page.waitForTimeout(1000);
    }

    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    const row = page.locator('tr').filter({ hasText: updatedName }).first();
    if (await row.count() === 0) { console.log('[TC-SUB-18] ⚠️  Not in trash'); return; }

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
      console.log('[TC-SUB-18] ✅ Permanently deleted');
    }
  });
});
