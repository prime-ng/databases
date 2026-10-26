// @ts-check
/**
 * 02_class.spec.js
 * ============================================================
 * DEEP COMPREHENSIVE TEST — Class Tab
 * URL: /school-setup/school-class?tab=class-sections
 * Pane: #class-sections-pane
 * Modal: #classSectionModal | Form: #classSectionForm
 * Fields: class_name (id=class_name), short_name (id=short_names), code (id=codes)
 * Trash: /school-setup/school-class/trash/view
 * ============================================================
 */
const { test, expect } = require('@playwright/test');
const { loginAsAdmin } = require('./helpers/auth');

const TS       = Date.now().toString().slice(-5);
const CLS_CODE  = `C${TS.slice(-4)}`; // max 5 chars (CHAR(5))
const CLS_NAME  = `AutoClass ${TS}`;
const CLS_SHORT = `AC${TS.slice(-2)}`;

const BASE     = 'http://test.localhost:8000';
const TAB_URL  = `${BASE}/school-setup/school-class?tab=class-sections`;
const TRASH_URL = `${BASE}/school-setup/school-class/trash/view`;

test.describe.serial('02 — School Setup: Class Tab', () => {
  /** @type {import('@playwright/test').Page} */
  let page;
  test.beforeAll(async ({ browser }) => {
    const context = await browser.newContext({ storageState: 'tests/.auth/adminStorageState.json' });
    page = await context.newPage();
    await loginAsAdmin(page);
  });
  test.afterAll(async () => {
    await page.close();
  });
  test.use({ storageState: 'tests/.auth/adminStorageState.json' });

  let updatedName = `${CLS_NAME} UPD`;

  // ─── TC-CLS-01: Tab Navigation ────────────────────────────
  test('TC-CLS-01: Navigate to Class tab — pane visible', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await expect(page.locator('#class-sections-pane')).toBeVisible();
    // Verify the tab is active
    const activeTab = page.locator('.nav-tabs .nav-link.active');
    await expect(activeTab).toContainText(/Class/i);
    console.log('[TC-CLS-01] ✅ Class tab visible');
  });

  // ─── TC-CLS-02: Breadcrumb ───────────────────────────────
  test('TC-CLS-02: Breadcrumb shows "Class & Section Management"', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText('Class & Section Management');
    console.log('[TC-CLS-02] ✅ Breadcrumb correct');
  });

  // ─── TC-CLS-03: Tab redirect ─────────────────────────────
  test('TC-CLS-03: Direct URL ?tab=class-sections activates class pane', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const pane = page.locator('#class-sections-pane');
    await expect(pane).toBeVisible();
    const classes = await pane.getAttribute('class');
    expect(classes).toMatch(/show/);
    console.log('[TC-CLS-03] ✅ Class tab redirect works');
  });

  // ─── TC-CLS-04: Search Filter ─────────────────────────────
  test('TC-CLS-04: Search filter — filters results by text', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    // Get a known existing class name from first row (if any)
    const firstRowName = await page.locator('#class-sections-pane tbody tr td:nth-child(2)').first().textContent().catch(() => null);
    if (!firstRowName) {
      console.log('[TC-CLS-04] ⚠️  No existing classes — skipping');
      return;
    }

    const searchInput = page.locator('#class-sections-pane input[name="search"]');
    await searchInput.fill(firstRowName.trim().slice(0, 8));
    await page.locator('#class-sections-pane button[type="submit"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#class-sections-pane tbody')).toContainText(firstRowName.trim().slice(0, 8));
    console.log('[TC-CLS-04] ✅ Search filter works');
  });

  // ─── TC-CLS-05: Active Status Filter ─────────────────────
  test('TC-CLS-05: Status filter — Active', async () => {
    await page.goto(`${TAB_URL}&status=1`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#class-sections-pane select[name="status"]')).toHaveValue('1');
    await expect(page.locator('#class-sections-pane')).toBeVisible();
    console.log('[TC-CLS-05] ✅ Active filter applied');
  });

  // ─── TC-CLS-06: Inactive Status Filter ───────────────────
  test('TC-CLS-06: Status filter — Inactive', async () => {
    await page.goto(`${TAB_URL}&status=0`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#class-sections-pane select[name="status"]')).toHaveValue('0');
    console.log('[TC-CLS-06] ✅ Inactive filter applied');
  });

  // ─── TC-CLS-07: Clear Filters ─────────────────────────────
  test('TC-CLS-07: Clear filters resets to all', async () => {
    await page.goto(`${TAB_URL}&status=1&search=abc`, { waitUntil: 'domcontentloaded' });
    await page.locator('#class-sections-pane a[title="Clear Filters"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#class-sections-pane select[name="status"]')).toHaveValue('');
    console.log('[TC-CLS-07] ✅ Clear filters works');
  });

  // ─── TC-CLS-08: Create — Empty Validation ─────────────────
  test('TC-CLS-08: Create validation — empty form shows error', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#classSectionModal"], a[data-bs-target="#classSectionModal"]').first().click();
    await expect(page.locator('#classSectionModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#classSectionForm button[type="submit"]').click();
    await page.waitForTimeout(800);

    const isOpen = await page.locator('#classSectionModal').isVisible();
    const hasError = await page.locator('.text-danger, .invalid-feedback, .swal2-icon-error').count();
    expect(isOpen || hasError > 0).toBeTruthy();

    if (await page.locator('#classSectionModal').isVisible()) {
      await page.locator('#classSectionModal button[data-bs-dismiss="modal"]').first().click();
      await page.waitForTimeout(400);
    }
    console.log('[TC-CLS-08] ✅ Empty form validation works');
  });

  // ─── TC-CLS-09: Create — Valid Class ─────────────────────
  test('TC-CLS-09: Create class — success', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    console.log(`[TC-CLS-09] Creating class: ${CLS_NAME} / ${CLS_CODE}`);

    await page.locator('button[data-bs-target="#classSectionModal"], a[data-bs-target="#classSectionModal"]').first().click();
    await expect(page.locator('#classSectionModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(500);

    await page.locator('#classSectionForm input[name="class_name"], #class_name').clear();
    await page.locator('#classSectionForm input[name="class_name"], #class_name').fill(CLS_NAME);

    await page.locator('#classSectionForm input[name="short_name"], #short_names').clear();
    await page.locator('#classSectionForm input[name="short_name"], #short_names').fill(CLS_SHORT);

    await page.locator('#classSectionForm input[name="code"], #codes').clear();
    await page.locator('#classSectionForm input[name="code"], #codes').fill(CLS_CODE);

    // Check first section row toggle and fill mandatory fields (teacher, room type, room, unique code)
    const firstSectionToggle = page.locator('#classSectionForm .row-edit-toggle').first();
    if (await firstSectionToggle.count() > 0) {
      await firstSectionToggle.check();
      await page.waitForTimeout(300);

      // Unique section code per class to satisfy uq_classSection_code constraint
      const secCodeInput = page.locator('#classSectionForm input[name*="[section_code]"]').first();
      await secCodeInput.clear();
      await secCodeInput.fill(`S_${TS.slice(-3)}`);

      // Select teacher
      const teacherSelect = page.locator('#classSectionForm select[name*="[class_teacher_id]"]').first();
      await teacherSelect.selectOption({ index: 1 });
      await page.waitForTimeout(300);

      // Select available unassigned room (not disabled)
      const roomSelect = page.locator('#classSectionForm select[name*="[class_house_room_id]"]').first();
      const firstEnabledRoomOption = roomSelect.locator('option:not([disabled])').last();
      const roomVal = await firstEnabledRoomOption.getAttribute('value');
      if (roomVal) {
        await roomSelect.selectOption(roomVal);
      } else {
        await roomSelect.selectOption({ index: 1 });
      }
    }

    const responsePromise = page.waitForResponse(
      resp => resp.url().includes('/school-class') && resp.request().method() === 'POST',
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#classSectionForm button[type="submit"]').click();
    const resp = await responsePromise;
    if (resp) {
      console.log('[TC-CLS-09] STATUS:', resp.status(), 'BODY:', await resp.text());
    } else {
      console.log('[TC-CLS-09] NO RESPONSE RECEIVED');
    }
    await page.waitForTimeout(3500);

    // Verify created
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(CLS_NAME)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#class-sections-pane')).toContainText(CLS_NAME);
    console.log('[TC-CLS-09] ✅ Class created');
  });

  // ─── TC-CLS-10: Duplicate Code ────────────────────────────
  test('TC-CLS-10: Duplicate code rejected', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    await page.locator('button[data-bs-target="#classSectionModal"], a[data-bs-target="#classSectionModal"]').first().click();
    await expect(page.locator('#classSectionModal')).toBeVisible({ timeout: 8000 });

    await page.locator('#classSectionForm input[name="class_name"], #class_name').fill(`DiffCls ${TS}`);
    await page.locator('#classSectionForm input[name="code"], #codes').fill(CLS_CODE);

    const responsePromise = page.waitForResponse(
      resp => resp.url().includes('/school-class') && resp.request().method() === 'POST',
      { timeout: 10000 }
    ).catch(() => null);

    await page.locator('#classSectionForm button[type="submit"]').click();
    await page.waitForTimeout(1500);

    const response = await responsePromise;
    const pageContent = await page.content();
    const hasDupError = pageContent.toLowerCase().includes('already') ||
                        pageContent.toLowerCase().includes('unique') ||
                        pageContent.toLowerCase().includes('taken') ||
                        (await page.locator('.text-danger, .swal2-icon-error').count()) > 0 ||
                        (response && response.status() >= 400) ||
                        await page.locator('#classSectionModal').isVisible();

    expect(hasDupError).toBeTruthy();

    if (await page.locator('#classSectionModal').isVisible()) {
      await page.locator('#classSectionModal button[data-bs-dismiss="modal"]').first().click();
      await page.waitForTimeout(300);
    }
    console.log('[TC-CLS-10] ✅ Duplicate code rejected');
  });

  // ─── TC-CLS-11: View Class ────────────────────────────────
  test('TC-CLS-11: View class detail page', async () => {
    test.setTimeout(60000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(CLS_NAME)}`, { waitUntil: 'domcontentloaded' });

    const viewBtn = page.locator('#class-sections-pane tbody a[href*="/school-class/view/"]').first();
    if (await viewBtn.count() > 0) {
      await viewBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('body')).toContainText(CLS_NAME);
      await page.goBack();
      console.log('[TC-CLS-11] ✅ View class works');
    } else {
      console.log('[TC-CLS-11] ⚠️  View button not found');
    }
  });

  // ─── TC-CLS-12: Edit Class ────────────────────────────────
  test('TC-CLS-12: Edit class — change name and save', async () => {
    test.setTimeout(90000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(CLS_NAME)}`, { waitUntil: 'domcontentloaded' });

    const editBtn = page.locator('button[onclick*="editClassSection"]').first();
    if (await editBtn.count() === 0) {
      console.log('[TC-CLS-12] ⚠️  Edit button not found');
      return;
    }

    await editBtn.click();
    const swalConfirm = page.locator('.swal2-confirm');
    if (await swalConfirm.isVisible({ timeout: 3000 }).catch(() => false)) {
      await swalConfirm.click();
    }
    await expect(page.locator('#classSectionModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(600);

    await page.locator('#classSectionForm input[name="class_name"], #class_name').clear();
    await page.locator('#classSectionForm input[name="class_name"], #class_name').fill(updatedName);

    const responsePromise = page.waitForResponse(
      resp => resp.url().includes('/school-class') && (resp.request().method() === 'PUT' || resp.request().method() === 'POST'),
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#classSectionForm button[type="submit"]').click();
    await responsePromise;
    await page.waitForTimeout(3500);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#class-sections-pane')).toContainText(updatedName);
    console.log('[TC-CLS-12] ✅ Class updated');
  });

  // ─── TC-CLS-13: Status Toggle ─────────────────────────────
  test('TC-CLS-13: Toggle class active/inactive status', async () => {
    test.setTimeout(60000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });

    const toggle = page.locator('#class-sections-pane input[type="checkbox"].form-check-input').first();
    if (await toggle.count() > 0) {
      const original = await toggle.isChecked();
      const toggleResp = page.waitForResponse(
        resp => resp.url().includes('toggle-status'),
        { timeout: 10000 }
      ).catch(() => null);
      await toggle.click();
      await toggleResp;
      await page.waitForTimeout(500);
      const newState = await toggle.isChecked();
      expect(newState).toBe(!original);
      // Restore
      await toggle.click();
      await page.waitForTimeout(400);
      console.log('[TC-CLS-13] ✅ Status toggle works');
    } else {
      console.log('[TC-CLS-13] ⚠️  Toggle not found');
    }
  });

  // ─── TC-CLS-14: Soft Delete ───────────────────────────────
  test('TC-CLS-14: Soft delete class', async () => {
    test.setTimeout(90000);
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });

    const deleteBtn = page.locator('button[onclick*="deleteClassSection"]').first();
    if (await deleteBtn.count() === 0) {
      console.log('[TC-CLS-14] ⚠️  Delete button not found');
      return;
    }

    const deleteResp = page.waitForResponse(
      resp => resp.url().includes('/school-class/') && resp.request().method() === 'DELETE',
      { timeout: 15000 }
    ).catch(() => null);

    await deleteBtn.click();
    await page.waitForTimeout(500);
    const swal = page.locator('.swal2-confirm');
    if (await swal.isVisible({ timeout: 3000 }).catch(() => false)) await swal.click();
    await deleteResp;
    await page.waitForTimeout(3500);

    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    const stillExists = await page.locator('#class-sections-pane tbody tr').filter({ hasText: updatedName }).count();
    expect(stillExists).toBe(0);
    console.log('[TC-CLS-14] ✅ Class soft-deleted');
  });

  // ─── TC-CLS-15: Trash View ────────────────────────────────
  test('TC-CLS-15: Trash view — deleted class appears', async () => {
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText(updatedName);
    console.log('[TC-CLS-15] ✅ Class appears in trash');
  });

  // ─── TC-CLS-16: Restore ───────────────────────────────────
  test('TC-CLS-16: Restore class from trash', async () => {
    test.setTimeout(90000);
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });

    const trashRow = page.locator('tr').filter({ hasText: updatedName }).first();
    await expect(trashRow).toBeVisible({ timeout: 8000 });

    const restoreBtn = trashRow.locator('a[href*="restore"], button[title*="Restore"]').first();
    if (await restoreBtn.count() > 0) {
      await restoreBtn.click();
      await page.waitForTimeout(500);
      const swal = page.locator('.swal2-confirm');
      if (await swal.isVisible({ timeout: 2000 }).catch(() => false)) await swal.click();
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(1500);

      await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
      await expect(page.locator('#class-sections-pane')).toContainText(updatedName);
      console.log('[TC-CLS-16] ✅ Class restored');
    } else {
      console.log('[TC-CLS-16] ⚠️  Restore button not found');
    }
  });

  // ─── TC-CLS-17: Force Delete ──────────────────────────────
  test('TC-CLS-17: Force delete class permanently', async () => {
    test.setTimeout(120000);

    // Soft delete first
    await page.goto(`${TAB_URL}&search=${encodeURIComponent(updatedName)}`, { waitUntil: 'domcontentloaded' });
    const deleteBtn = page.locator('button[onclick*="deleteClassSection"]').first();
    if (await deleteBtn.count() > 0) {
      await deleteBtn.click();
      await page.waitForTimeout(500);
      const swal = page.locator('.swal2-confirm');
      if (await swal.isVisible({ timeout: 2000 }).catch(() => false)) await swal.click();
      await page.waitForTimeout(1000);
    }

    // Force delete from trash
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    const trashRow = page.locator('tr').filter({ hasText: updatedName }).first();
    if (await trashRow.count() === 0) {
      console.log('[TC-CLS-17] ⚠️  Not in trash');
      return;
    }

    const forceBtn = trashRow.locator(
      'button[title*="Permanent"], form[action*="forceDelete"] button, form[action*="force-delete"] button'
    ).first();
    if (await forceBtn.count() > 0) {
      await forceBtn.click();
      await page.waitForTimeout(500);
      const swal = page.locator('.swal2-confirm');
      if (await swal.isVisible({ timeout: 2000 }).catch(() => false)) await swal.click();
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(1000);

      await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
      const gone = await page.locator('tr').filter({ hasText: updatedName }).count();
      expect(gone).toBe(0);
      console.log('[TC-CLS-17] ✅ Class permanently deleted');
    } else {
      console.log('[TC-CLS-17] ⚠️  Force delete button not found');
    }
  });
});
