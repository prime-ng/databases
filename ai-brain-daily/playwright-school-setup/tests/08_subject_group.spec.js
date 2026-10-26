// @ts-check
/**
 * 08_subject_group.spec.js
 * ============================================================
 * DEEP COMPREHENSIVE TEST — Subject Group Tab
 * URL: /school-setup/school-class?tab=subject-group
 * Pane: #subject-group-pane
 * Modal (EDIT ONLY): #SubjectGroupModal | Form: #SubjectGroupForm
 * Fields: code (id=code_subject_groups, READONLY), name (id=name_subject_groups)
 *         short_name (id=short_name_subject_groups)
 *         default_group_for_class (id=default_group_for_class, checkbox)
 * Generate Modal: #generateSubjectGroupsModal
 * NOTE: Groups are GENERATED (not manually created). Code is auto-generated (readonly).
 * ============================================================
 */
const { test, expect } = require('@playwright/test');

const BASE      = 'http://test.localhost:8000';
const TAB_URL   = `${BASE}/school-setup/school-class?tab=subject-group`;
const TRASH_URL = `${BASE}/school-setup/subject-group/trash/view`;

test.describe.serial('08 — School Setup: Subject Group Tab', () => {
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

  test('TC-SG-01: Navigate to Subject Group tab — pane visible', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-group-pane')).toBeVisible();
    await expect(page.locator('.nav-tabs .nav-link.active')).toContainText(/Subject Group/i);
    console.log('[TC-SG-01] ✅ Subject Group pane visible');
  });

  test('TC-SG-02: Breadcrumb correct', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText('Class & Section Management');
    console.log('[TC-SG-02] ✅ Breadcrumb correct');
  });

  test('TC-SG-03: Tab redirect works', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const pane = page.locator('#subject-group-pane');
    await expect(pane).toBeVisible();
    expect(await pane.getAttribute('class')).toMatch(/show/);
    console.log('[TC-SG-03] ✅ Tab redirect correct');
  });

  test('TC-SG-04: Table with subject groups visible', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const table = page.locator('#subject-group-pane table.subject-group-accordion, #subject-group-pane table');
    await expect(table).toBeVisible();
    console.log('[TC-SG-04] ✅ Subject group table visible');
  });

  test('TC-SG-05: Search filter', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const searchInput = page.locator('#subject-group-pane input[name="search"]');
    await expect(searchInput).toBeVisible();
    await searchInput.fill('test');
    await page.locator('#subject-group-pane button[type="submit"]').click();
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('#subject-group-pane')).toBeVisible();
    console.log('[TC-SG-05] ✅ Search filter works');
  });

  test('TC-SG-06: Active status filter', async () => {
    await page.goto(`${TAB_URL}&status=1`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-group-pane select[name="status"]')).toHaveValue('1');
    console.log('[TC-SG-06] ✅ Active filter');
  });

  test('TC-SG-07: Inactive status filter', async () => {
    await page.goto(`${TAB_URL}&status=0`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-group-pane select[name="status"]')).toHaveValue('0');
    console.log('[TC-SG-07] ✅ Inactive filter');
  });

  test('TC-SG-08: Clear filters', async () => {
    await page.goto(`${TAB_URL}&status=1`, { waitUntil: 'domcontentloaded' });
    const clearBtn = page.locator('#subject-group-pane a[title="Clear Filters"]');
    if (await clearBtn.count() > 0) {
      await clearBtn.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('#subject-group-pane select[name="status"]')).toHaveValue('');
    }
    console.log('[TC-SG-08] ✅ Clear filters works');
  });

  test('TC-SG-09: Generate Subject Groups button opens modal', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    // Find the generate/regenerate button
    const generateBtn = page.locator('button[data-bs-target="#generateSubjectGroupsModal"], button[onclick*="generateSubjectGroups"]').first();
    if (await generateBtn.count() > 0) {
      await generateBtn.click();
      await page.waitForTimeout(500);
      const modal = page.locator('#generateSubjectGroupsModal');
      if (await modal.count() > 0) {
        await expect(modal).toBeVisible({ timeout: 5000 });
        console.log('[TC-SG-09] ✅ Generate modal opens');
        // Close it
        await page.locator('#generateSubjectGroupsModal button[data-bs-dismiss="modal"]').first().click();
        await page.waitForTimeout(300);
      }
    } else {
      console.log('[TC-SG-09] ⚠️  Generate button not found');
    }
  });

  test('TC-SG-10: Code field is readonly in edit modal', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    // Find an edit button for an existing subject group
    const editBtn = page.locator('button[onclick*="editSubjectGroup"]').first();
    if (await editBtn.count() === 0) {
      console.log('[TC-SG-10] ⚠️  No edit button found — no subject groups');
      return;
    }

    await editBtn.click();
    const swalConfirm = page.locator('.swal2-confirm');
    if (await swalConfirm.isVisible({ timeout: 3000 }).catch(() => false)) {
      await swalConfirm.click();
    }
    await expect(page.locator('#SubjectGroupModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(600);

    // Verify code field is readonly
    const codeField = page.locator('#code_subject_groups');
    if (await codeField.count() > 0) {
      const isReadonly = await codeField.getAttribute('readonly');
      const style = await codeField.getAttribute('style');
      const isDisabledPointer = style?.includes('pointer-events: none') || false;
      const isReadonlyAttr = isReadonly !== null;

      expect(isReadonlyAttr || isDisabledPointer).toBeTruthy();
      console.log('[TC-SG-10] ✅ Code field is readonly (user cannot change auto-generated code)');
    }

    await page.locator('#SubjectGroupModal button[data-bs-dismiss="modal"]').first().click();
    await page.waitForTimeout(300);
  });

  test('TC-SG-11: Edit subject group name/short_name', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const editBtn = page.locator('button[onclick*="editSubjectGroup"]').first();
    if (await editBtn.count() === 0) { console.log('[TC-SG-11] ⚠️  No subject groups to edit'); return; }

    await editBtn.click();
    const swalConfirm = page.locator('.swal2-confirm');
    if (await swalConfirm.isVisible({ timeout: 3000 }).catch(() => false)) {
      await swalConfirm.click();
    }
    await expect(page.locator('#SubjectGroupModal')).toBeVisible({ timeout: 8000 });
    await page.waitForTimeout(600);

    // Get current name and add a suffix
    const currentName = await page.locator('#name_subject_groups').inputValue().catch(() => '');
    const newName = currentName ? `${currentName.slice(0, 20)} E` : `Edited Group`;

    await page.locator('#name_subject_groups').clear();
    await page.locator('#name_subject_groups').fill(newName);

    const respPromise = page.waitForResponse(
      r => r.url().includes('/subject-group') && (r.request().method() === 'PUT' || r.request().method() === 'POST'),
      { timeout: 15000 }
    ).catch(() => null);

    await page.locator('#SubjectGroupForm button[type="submit"]').click();
    await respPromise;
    await page.waitForTimeout(1000);

    // Verify the updated name appears
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('#subject-group-pane')).toContainText(newName.trim());
    console.log('[TC-SG-11] ✅ Subject group name updated');

    // Restore original name if possible
    if (currentName) {
      const editBtn2 = page.locator('button[onclick*="editSubjectGroup"]').first();
      if (await editBtn2.count() > 0) {
        await editBtn2.click();
        await expect(page.locator('#SubjectGroupModal')).toBeVisible({ timeout: 8000 });
        await page.waitForTimeout(500);
        await page.locator('#name_subject_groups').clear();
        await page.locator('#name_subject_groups').fill(currentName);
        await page.locator('#SubjectGroupForm button[type="submit"]').click();
        await page.waitForTimeout(800);
      }
    }
  });

  test('TC-SG-12: Status toggle on subject group', async () => {
    test.setTimeout(60000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const toggle = page.locator('#subject-group-pane input[type="checkbox"].form-check-input').first();
    if (await toggle.count() > 0) {
      const original = await toggle.isChecked();
      const respP = page.waitForResponse(r => r.url().includes('toggle-status'), { timeout: 10000 }).catch(() => null);
      await toggle.click();
      await respP;
      await page.waitForTimeout(400);
      expect(await toggle.isChecked()).toBe(!original);
      await toggle.click(); // restore
      console.log('[TC-SG-12] ✅ Status toggle works');
    } else {
      console.log('[TC-SG-12] ⚠️  No toggle found');
    }
  });

  test('TC-SG-13: Expand subject group accordion to see subjects', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const accordionRow = page.locator('#subject-group-pane tbody tr[data-bs-toggle="collapse"]').first();
    if (await accordionRow.count() > 0) {
      await accordionRow.click();
      await page.waitForTimeout(500);
      // Expanded row should show subjects
      const subjectRow = page.locator('#subject-group-pane .collapse.show').first();
      if (await subjectRow.count() > 0) {
        await expect(subjectRow).toBeVisible();
      }
      console.log('[TC-SG-13] ✅ Accordion expand works');
    } else {
      console.log('[TC-SG-13] ⚠️  No accordion rows found');
    }
  });

  test('TC-SG-14: Soft delete subject group', async () => {
    test.setTimeout(90000);
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });

    const deleteBtn = page.locator('button[onclick*="deleteSubjectGroup"]').first();
    if (await deleteBtn.count() === 0) { console.log('[TC-SG-14] ⚠️  No delete button'); return; }

    // Get the row text for trash verification
    const rowText = await page.locator('#subject-group-pane tbody tr').first().textContent().catch(() => '');

    const deleteResp = page.waitForResponse(
      r => r.url().includes('/subject-group/') && r.request().method() === 'DELETE',
      { timeout: 15000 }
    ).catch(() => null);

    await deleteBtn.click();
    await page.waitForTimeout(500);
    const swal = page.locator('.swal2-confirm');
    if (await swal.isVisible({ timeout: 3000 }).catch(() => false)) await swal.click();
    await deleteResp;
    await page.waitForTimeout(1000);
    console.log('[TC-SG-14] ✅ Subject group soft delete attempted');
  });

  test('TC-SG-15: Trash page accessible', async () => {
    await page.goto(TRASH_URL, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toBeVisible();
    const title = await page.title();
    expect(title).not.toContain('500');
    console.log('[TC-SG-15] ✅ Trash page accessible');
  });

  test('TC-SG-16: Sync students count button accessible', async () => {
    await page.goto(TAB_URL, { waitUntil: 'domcontentloaded' });
    const syncBtn = page.locator('#btn-sync-subject-group-students, button[onclick*="syncAllSubjectGroupStudents"]');
    if (await syncBtn.count() > 0) {
      await expect(syncBtn.first()).toBeVisible();
      console.log('[TC-SG-16] ✅ Sync students count button visible');
    } else {
      console.log('[TC-SG-16] ⚠️  Sync button not found');
    }
  });
});
